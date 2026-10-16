// PostToolUse hook (Write|Edit): converts the file Claude just wrote to CRLF line endings,
// because every text file in this repo must be CRLF. Only touches files inside the project, skips binaries.
const fs = require("fs");
const path = require("path");

const BINARY = new Set([".png", ".jpg", ".jpeg", ".gif", ".bmp", ".ico", ".ttf", ".otf", ".vlw", ".jar", ".zip", ".pdf"]);

let input = "";
process.stdin.on("data", (chunk) => (input += chunk));
process.stdin.on("end", () => {
  const data = JSON.parse(input);
  const file = (data.tool_response && data.tool_response.filePath) || (data.tool_input && data.tool_input.file_path);
  if (!file) return;

  const project = path.resolve(process.env.CLAUDE_PROJECT_DIR || process.cwd());
  const resolved = path.resolve(file);
  const relative = path.relative(project, resolved);
  if (relative.startsWith("..") || path.isAbsolute(relative)) return; // Outside the project
  if (relative.split(path.sep)[0] === ".git") return;
  if (BINARY.has(path.extname(resolved).toLowerCase()) || !fs.existsSync(resolved)) return;

  const content = fs.readFileSync(resolved);
  if (content.includes(0)) return; // Binary content

  const text = content.toString("utf8");
  const converted = text.replace(/\r?\n/g, "\r\n");
  if (converted !== text) fs.writeFileSync(resolved, converted, "utf8");
});
