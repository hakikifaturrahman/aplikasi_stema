from pypdf import PdfReader
reader = PdfReader("d:/apk_pui/pui.pdf")
text = ""
for page in reader.pages:
    text += page.extract_text() + "\n"
with open("d:/apk_pui/pui_output.txt", "w", encoding="utf-8") as f:
    f.write(text)
