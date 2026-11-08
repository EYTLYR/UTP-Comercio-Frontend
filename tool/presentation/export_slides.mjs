import fs from 'node:fs/promises';
import path from 'node:path';
import {pathToFileURL} from 'node:url';

const root = process.cwd();
const runtime = 'C:/Program Files/WindowsApps/OpenAI.CodexPrimaryRuntime.v26-1105-1297-0_26.1105.1297.0_x64__3k8sg7r9htsxt/dependencies';
process.env.RUNTIME_NODE_MODULES = path.join(runtime, 'node/node_modules');
process.env.RUNTIME_NODE = path.join(runtime, 'node/bin/node.exe');
const skill = 'C:/Users/CDani/.codex/plugins/cache/openai-primary-runtime/presentations/26.1105.12137/skills/presentations';
const {Presentation, PresentationFile} = await import(pathToFileURL(path.join(runtime, 'node/node_modules/@oai/artifact-tool/dist/artifact_tool.mjs')).href);
const {finalizePresentation} = await import(pathToFileURL(path.join(skill, 'container_tools/artifact_tool_utils.mjs')).href);
const build = path.join(root, 'build/slides-nearby-v2');
const source = JSON.parse(await fs.readFile(path.join(build, 'export-source.json'), 'utf8'),
  (key,value) => value && typeof value === 'object' && typeof value.__bytes === 'string'
    ? new Uint8Array(Buffer.from(value.__bytes, 'base64')) : value);
const presentation = await Presentation.load(source);
if (presentation.slides.items.length !== 17) throw new Error('Cantidad de diapositivas inesperada');
const candidate = path.join(build, 'candidate.pptx');
await (await PresentationFile.exportPptx(presentation)).save(candidate);
const finalPath = path.join(root, 'docs/presentation/Nearby_Presentacion_Ampliada.pptx');
const report = await finalizePresentation({
  workspaceDir: root,
  candidatePath: candidate,
  finalPath,
  pythonExecutable: path.join(runtime, 'python/python.exe'),
  integrityValidatorPath: path.join(skill, 'container_tools/inspect_presentation_package_integrity.py'),
  layoutValidatorPath: path.join(skill, 'container_tools/inspect_presentation_layout_geometry.py'),
  layoutArgs: ['--expected-slide-size-emu', '12192000,6858000', '--validate-bullet-geometry', '--validate-heading-fit'],
  requiredNativeTableOwnerSlides: [],
  requiredNativeChartOwnerSlides: [],
  fontPolicy: {basis:'design', families:['Poppins']},
  verifyArtifactToolImport: true,
  receiptPath: path.join(build, 'validation-ampliada.json'),
});
console.log(JSON.stringify({finalPath, validation:report}, null, 2));
