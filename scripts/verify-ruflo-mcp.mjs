import { Client } from '@modelcontextprotocol/sdk/client/index.js';
import { StdioClientTransport } from '@modelcontextprotocol/sdk/client/stdio.js';
import { dirname, resolve } from 'node:path';

const [dbPath, query, key] = process.argv.slice(2);
if (!dbPath || !query) throw new Error('Usage: node verify-ruflo-mcp.mjs <db-path> <query> [key]');
const factory = resolve(import.meta.dirname, '..');
const transport = new StdioClientTransport({
  command: process.execPath,
  args: [resolve(factory, 'node_modules/ruflo/bin/ruflo.js'), 'mcp', 'start'],
  env: { ...process.env, CLAUDE_FLOW_DB_PATH: resolve(dbPath), CLAUDE_FLOW_MEMORY_PATH: dirname(resolve(dbPath)) },
});
const client = new Client({ name: 'ruflo-site-isolation-check', version: '1.0.0' });
try {
  await client.connect(transport);
  const { tools } = await client.listTools();
  const tool = tools.find(({ name }) => name === 'memory_search');
  if (!tool) throw new Error('Ruflo memory_search is unavailable');
  const result = await client.callTool({ name: 'memory_search', arguments: { query } });
  console.log(`memory_search_result=${JSON.stringify(result)}`);
  if (key) {
    const retrieved = await client.callTool({ name: 'memory_retrieve', arguments: { key, namespace: 'migration-verification' } });
    console.log(`memory_retrieve_result=${JSON.stringify(retrieved)}`);
  }
} finally {
  await client.close();
}
