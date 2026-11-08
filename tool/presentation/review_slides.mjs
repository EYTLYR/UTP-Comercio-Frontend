import fs from 'node:fs/promises';
import path from 'node:path';
import {pathToFileURL} from 'node:url';
const runtime = 'C:/Program Files/WindowsApps/OpenAI.CodexPrimaryRuntime.v26-1105-1297-0_26.1105.1297.0_x64__3k8sg7r9htsxt/dependencies';
const {PresentationFile,FileBlob} = await import(pathToFileURL(path.join(runtime,'node/node_modules/@oai/artifact-tool/dist/artifact_tool.mjs')).href);
const root=process.cwd();
const source=path.join(root,'docs/presentation/Nearby_Presentacion_Ampliada.pptx');
const deck=await PresentationFile.importPptx(await FileBlob.load(source));
const out=path.join(root,'build/slides-nearby-v2/final');
await fs.mkdir(out,{recursive:true});
for (let i=0;i<deck.slides.items.length;i++) {
  const png=await deck.export({slide:deck.slides.items[i],format:'png',scale:1});
  await fs.writeFile(path.join(out,`slide-${String(i+1).padStart(2,'0')}.png`),new Uint8Array(await png.arrayBuffer()));
}
console.log(JSON.stringify({slides:deck.slides.items.length,rendered:out}));
