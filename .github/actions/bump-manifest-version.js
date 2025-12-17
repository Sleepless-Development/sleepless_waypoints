const fs = require("fs");

const fxManifest = fs.readFileSync("./fxmanifest.lua", "utf8");

let newVersion = process.env.TGT_RELEASE_VERSION;
newVersion = newVersion.replace("v", "");

const newFileContent = fxManifest.replace(
  /\bversion\s+(.*)$/gm,
  `version '${newVersion}'`
);

fs.writeFileSync("./fxmanifest.lua", newFileContent);
