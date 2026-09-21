import { readFile, writeFile } from 'node:fs/promises';
import { pathToFileURL } from 'node:url';

const projects = {
  prod: 'flutterkaigi-2026-283db',
  stg: 'flutterkaigi-2026-stg',
};

// PUT はテンプレート全体を置き換えるため、Console で管理しているものも含め、
// 更新対象外のパラメータ・グループ・条件を保持する。
export function mergeDefaults(template, defaults) {
  const result = structuredClone(template);
  delete result.version;
  delete result.etag;
  result.parameters ??= {};
  for (const [key, value] of Object.entries(defaults)) {
    const containers = [result.parameters,
      ...Object.values(result.parameterGroups ?? {}).map(group => group.parameters ?? {})];
    const existing = containers.filter(parameters => Object.hasOwn(parameters, key));
    if (existing.length > 1) throw new Error(`Remote Config のキーが重複しています: ${key}`);
    const parameters = existing[0] ?? result.parameters;
    // 条件付きの配信設定を、初期値の適用で上書きしない。
    if (Object.keys(parameters[key]?.conditionalValues ?? {}).length > 0) {
      throw new Error(`${key} に条件付きの値があります。初期値の適用前に Firebase Console で確認してください。`);
    }
    parameters[key] = { ...parameters[key], ...value };
  }
  return result;
}

export async function updateRemoteConfig({ environment, apply = false, backupPath, token, request = fetch }) {
  const project = projects[environment];
  if (!project) throw new Error('環境は prod または stg を指定してください。');
  if (!token) throw new Error('FIREBASE_ACCESS_TOKEN に短期間有効な Google アクセストークンを設定してください。');
  if (apply && !backupPath) throw new Error('適用にはバージョン管理対象外の --backup=<path> が必要です。');
  const defaults = JSON.parse(await readFile(
    new URL(`../packages/data/firebase/remoteconfig.${environment}.json`, import.meta.url), 'utf8'));
  const endpoint = `https://firebaseremoteconfig.googleapis.com/v1/projects/${project}/remoteConfig`;
  const headers = { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' };
  const currentResponse = await request(endpoint, { headers });
  if (!currentResponse.ok) throw new Error(`Remote Config の取得に失敗しました（HTTP ${currentResponse.status}）。`);
  const etag = currentResponse.headers.get('etag');
  if (!etag) throw new Error('ETag を取得できなかったため、上書きを中止します。');
  const current = await currentResponse.json();
  const next = mergeDefaults(current, defaults);
  const changes = Object.keys(defaults).filter(key => {
    const previous = current.parameters?.[key] ?? Object.values(current.parameterGroups ?? {})
      .map(group => group.parameters?.[key]).find(Boolean);
    return previous?.defaultValue?.value !== defaults[key].defaultValue.value
      || previous?.valueType !== defaults[key].valueType
      || previous?.description !== defaults[key].description;
  });
  console.log(JSON.stringify({ project, previousVersion: current.version?.versionNumber ?? null,
    changedKeys: changes, defaults }, null, 2));
  if (changes.length === 0) return { changed: false };
  const options = { method: 'PUT', headers: { ...headers, 'If-Match': etag }, body: JSON.stringify(next) };
  const validation = await request(`${endpoint}?validate_only=true`, options);
  if (!validation.ok) throw new Error(`Remote Config の検証に失敗しました（HTTP ${validation.status}）。公開していません。`);
  if (!apply) {
    console.log('検証済みです。公開するには --apply と --backup=<path> を指定してください。');
    return { changed: false, plannedKeys: changes };
  }
  await writeFile(backupPath, JSON.stringify(current, null, 2) + '\n', { mode: 0o600, flag: 'wx' });
  const published = await request(endpoint, options);
  if (!published.ok) throw new Error(`Remote Config の公開に失敗しました（HTTP ${published.status}）。412 の場合は差分を取得し直してください。強制上書きは行いません。`);
  const result = await published.json();
  console.log(`${project} の Remote Config バージョン ${result.version?.versionNumber ?? '不明'} を公開しました。`);
  return { changed: true, version: result.version?.versionNumber };
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  const args = process.argv.slice(2);
  const environment = args.find(arg => arg.startsWith('--environment='))?.split('=')[1];
  const backupPath = args.find(arg => arg.startsWith('--backup='))?.slice('--backup='.length);
  try {
    for (const arg of args) {
      if (arg !== '--apply' && !arg.startsWith('--environment=') && !arg.startsWith('--backup=')) {
        throw new Error(`不明な引数です: ${arg}`);
      }
    }
    await updateRemoteConfig({ environment, backupPath, apply: args.includes('--apply'), token: process.env.FIREBASE_ACCESS_TOKEN });
  } catch (error) {
    console.error(error.message);
    process.exitCode = 1;
  }
}
