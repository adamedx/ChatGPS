//
// Copyright (c), Adam Edwards
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

using System.ComponentModel;
using System.IO;
using System.Text;
using DocumentFormat.OpenXml;
using DocumentFormat.OpenXml.Packaging;
using DocumentFormat.OpenXml.Wordprocessing;

namespace Modulus.ChatGPS.Plugins;

[Description("Enables the ability to read the contents of Microsoft Word documents (.docx) in the local file system and to append text to them.")]
public sealed class DocumentNativePlugin
{
    [Description("Read all text from a document.")]
    public string read_text_async([Description("Path to the file to read")] string filePath)
    {
        using var stream = File.OpenRead(filePath);
        using WordprocessingDocument document = WordprocessingDocument.Open(stream, false);

        return ReadText(document);
    }

    [Description("Append text to a document. If the document doesn't exist, it will be created.")]
    public void append_text_async([Description("Text to append")] string text, [Description("Destination file path")] string filePath)
    {
        if ( File.Exists(filePath) )
        {
            using var stream = File.Open(filePath, FileMode.Open, FileAccess.ReadWrite, FileShare.None);
            using WordprocessingDocument document = WordprocessingDocument.Open(stream, true);

            AppendText(document, text);
        }
        else
        {
            using var stream = new FileStream(filePath, FileMode.CreateNew, FileAccess.ReadWrite, FileShare.None);
            using WordprocessingDocument document = WordprocessingDocument.Create(stream, WordprocessingDocumentType.Document);

            Initialize(document);
            AppendText(document, text);
        }
    }

    private static string ReadText(WordprocessingDocument document)
    {
        var mainPart = document.MainDocumentPart ?? throw new InvalidOperationException("The main document part is missing.");
        var body = mainPart.Document.Body ?? throw new InvalidOperationException("The document body is missing.");

        var builder = new StringBuilder();

        foreach ( var para in body.Descendants<Paragraph>() )
        {
            builder.AppendLine(para.InnerText);
        }

        return builder.ToString();
    }

    private static void Initialize(WordprocessingDocument document)
    {
        MainDocumentPart mainPart = document.AddMainDocumentPart();

        mainPart.Document = new Document();
        mainPart.Document.AppendChild(new Body());
    }

    private static void AppendText(WordprocessingDocument document, string text)
    {
        var mainPart = document.MainDocumentPart ?? throw new InvalidOperationException("The main document part is missing.");
        var body = mainPart.Document.Body ?? throw new InvalidOperationException("The document body is missing.");

        Paragraph para = body.AppendChild(new Paragraph());
        Run run = para.AppendChild(new Run());
        run.AppendChild(new Text(text));
    }
}
