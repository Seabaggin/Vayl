#!/usr/bin/env node
'use strict';

/*
 * Graph topology analyzer for tour building.
 * Usage: node ua-tour-analyze.js <input.json> <output.json>
 */

function main() {
  const [, , inputPath, outputPath] = process.argv;
  if (!inputPath || !outputPath) {
    console.error('Usage: node ua-tour-analyze.js <input.json> <output.json>');
    process.exit(1);
  }

  const fs = require('fs');
  let data;
  try {
    data = JSON.parse(fs.readFileSync(inputPath, 'utf8'));
  } catch (e) {
    console.error('Failed to read/parse input: ' + e.message);
    process.exit(1);
  }

  const nodes = Array.isArray(data.nodes) ? data.nodes : [];
  const edges = Array.isArray(data.edges) ? data.edges : [];
  const layers = Array.isArray(data.layers) ? data.layers : [];

  if (nodes.length === 0) {
    console.error('No nodes in input.');
    process.exit(1);
  }

  // ---- Index nodes ----
  const nodeById = new Map();
  for (const n of nodes) nodeById.set(n.id, n);

  const nameOf = (id) => (nodeById.get(id) ? nodeById.get(id).name : id);
  const summaryOf = (id) => (nodeById.get(id) ? (nodeById.get(id).summary || '') : '');
  const typeOf = (id) => (nodeById.get(id) ? nodeById.get(id).type : '');
  const pathOf = (id) => (nodeById.get(id) ? (nodeById.get(id).filePath || '') : '');

  // Edge type buckets we treat as "dependency / call" flow for reading order.
  // This graph uses depends_on (dominant), calls, imports, exports.
  const DEP_EDGE_TYPES = new Set(['depends_on', 'imports', 'calls']);
  // Structural / hierarchy edges (kept out of fan-in importance to avoid
  // container nodes dominating purely by virtue of "contains").
  const STRUCT_EDGE_TYPES = new Set(['contains', 'migrates', 'configures']);

  // ---- Fan-in / Fan-out (only count edges between REAL nodes) ----
  // Fan-in/out for "importance" excludes pure structural containment edges so
  // that widely-depended-upon code surfaces, not just folder containers.
  const fanIn = new Map();
  const fanOut = new Map();
  for (const id of nodeById.keys()) {
    fanIn.set(id, 0);
    fanOut.set(id, 0);
  }
  for (const e of edges) {
    const s = e.source;
    const t = e.target;
    if (!nodeById.has(s) || !nodeById.has(t)) continue; // skip sub-file / phantom ids
    if (s === t) continue;
    if (STRUCT_EDGE_TYPES.has(e.type)) continue;
    fanOut.set(s, fanOut.get(s) + 1);
    fanIn.set(t, fanIn.get(t) + 1);
  }

  const fanInRanking = [...fanIn.entries()]
    .map(([id, c]) => ({ id, fanIn: c, name: nameOf(id) }))
    .sort((a, b) => b.fanIn - a.fanIn || a.id.localeCompare(b.id))
    .slice(0, 20);

  const fanOutRanking = [...fanOut.entries()]
    .map(([id, c]) => ({ id, fanOut: c, name: nameOf(id) }))
    .sort((a, b) => b.fanOut - a.fanOut || a.id.localeCompare(b.id))
    .slice(0, 20);

  // ---- Entry point scoring ----
  const codeEntryNames = new Set([
    'index.ts', 'index.js', 'main.ts', 'main.js', 'app.ts', 'app.js',
    'server.ts', 'server.js', 'mod.rs', 'main.go', 'main.py', 'main.rs',
    'manage.py', 'app.py', 'wsgi.py', 'asgi.py', 'run.py', '__main__.py',
    'Application.java', 'Main.java', 'Program.cs', 'config.ru', 'index.php',
    'App.swift', 'Application.kt', 'main.cpp', 'main.c',
    // Swift app conventions in this project:
    'VaylApp.swift'
  ]);

  // fan-out top 10% threshold
  const fanOutVals = [...fanOut.values()].sort((a, b) => b - a);
  const top10idx = Math.max(0, Math.floor(fanOutVals.length * 0.1) - 1);
  const fanOutTop10Threshold = fanOutVals.length ? fanOutVals[top10idx] : 0;
  // fan-in bottom 25% threshold
  const fanInValsAsc = [...fanIn.values()].sort((a, b) => a - b);
  const bottom25idx = Math.max(0, Math.floor(fanInValsAsc.length * 0.25) - 1);
  const fanInBottom25Threshold = fanInValsAsc.length ? fanInValsAsc[bottom25idx] : 0;

  const entryScores = [];
  for (const n of nodes) {
    let score = 0;
    const fp = (n.filePath || '').replace(/\\/g, '/');
    const depthSegs = fp ? fp.split('/').length : 99;

    if (n.type === 'document' || /\.md$/i.test(n.name || '')) {
      if ((n.name || '').toLowerCase() === 'readme.md' && depthSegs <= 1) {
        score += 5;
      } else {
        score += 2;
      }
    } else {
      // code-ish files
      if (codeEntryNames.has(n.name)) score += 3;
      // Project root or one level deep (e.g. src/index.ts -> 2 segs, app/Foo.swift -> 2 segs)
      if (depthSegs <= 2) score += 1;
      // High fan-out (top 10%)
      if ((fanOut.get(n.id) || 0) >= fanOutTop10Threshold && fanOutTop10Threshold > 0) score += 1;
      // Low fan-in (bottom 25%)
      if ((fanIn.get(n.id) || 0) <= fanInBottom25Threshold) score += 1;
    }

    if (score > 0) {
      entryScores.push({
        id: n.id,
        score,
        name: n.name,
        type: n.type,
        summary: (n.summary || '').slice(0, 240)
      });
    }
  }
  entryScores.sort((a, b) => b.score - a.score || (b.name === 'VaylApp.swift' ? 1 : 0) || a.id.localeCompare(b.id));
  const entryPointCandidates = entryScores.slice(0, 8);

  // Pick the top CODE entry for BFS (skip documents).
  let codeEntry = null;
  for (const c of entryScores) {
    if (c.type !== 'document' && !/\.md$/i.test(c.name || '')) {
      codeEntry = c.id;
      break;
    }
  }
  // Hard preference: VaylApp.swift if present (explicit @main per dispatch).
  for (const n of nodes) {
    if (n.name === 'VaylApp.swift') { codeEntry = n.id; break; }
  }
  if (!codeEntry) codeEntry = nodes[0].id;

  // ---- Build forward adjacency for dependency/call edges (real nodes only) ----
  const adj = new Map();
  for (const id of nodeById.keys()) adj.set(id, []);
  for (const e of edges) {
    if (!DEP_EDGE_TYPES.has(e.type)) continue;
    if (!nodeById.has(e.source) || !nodeById.has(e.target)) continue;
    if (e.source === e.target) continue;
    adj.get(e.source).push(e.target);
  }

  // ---- BFS from code entry ----
  const order = [];
  const depthMap = {};
  const visited = new Set();
  const queue = [[codeEntry, 0]];
  visited.add(codeEntry);
  while (queue.length) {
    const [cur, d] = queue.shift();
    order.push(cur);
    depthMap[cur] = d;
    const neighbors = (adj.get(cur) || []).slice().sort((a, b) => a.localeCompare(b));
    for (const nb of neighbors) {
      if (!visited.has(nb)) {
        visited.add(nb);
        queue.push([nb, d + 1]);
      }
    }
  }
  const byDepth = {};
  for (const id of order) {
    const d = String(depthMap[id]);
    if (!byDepth[d]) byDepth[d] = [];
    byDepth[d].push(id);
  }

  // ---- Non-code file inventory ----
  const nonCodeFiles = {
    documentation: [],
    infrastructure: [],
    data: [],
    config: []
  };
  const DOC_TYPES = new Set(['document']);
  const INFRA_TYPES = new Set(['service', 'pipeline', 'resource']);
  const DATA_TYPES = new Set(['table', 'schema', 'endpoint']);
  const CONFIG_TYPES = new Set(['config']);
  for (const n of nodes) {
    const rec = { id: n.id, name: n.name, type: n.type, summary: (n.summary || '').slice(0, 300) };
    if (DOC_TYPES.has(n.type)) nonCodeFiles.documentation.push(rec);
    else if (INFRA_TYPES.has(n.type)) nonCodeFiles.infrastructure.push(rec);
    else if (DATA_TYPES.has(n.type)) nonCodeFiles.data.push(rec);
    else if (CONFIG_TYPES.has(n.type)) nonCodeFiles.config.push(rec);
  }

  // ---- Tightly coupled clusters (bidirectional dep/call pairs, expanded) ----
  // Build undirected dep edge set + directed presence to detect bidirectional.
  const directed = new Set();
  const undirectedNeighbors = new Map();
  for (const id of nodeById.keys()) undirectedNeighbors.set(id, new Set());
  for (const e of edges) {
    if (!DEP_EDGE_TYPES.has(e.type)) continue;
    if (!nodeById.has(e.source) || !nodeById.has(e.target)) continue;
    if (e.source === e.target) continue;
    directed.add(e.source + '||' + e.target);
    undirectedNeighbors.get(e.source).add(e.target);
    undirectedNeighbors.get(e.target).add(e.source);
  }

  // Seed clusters from bidirectional pairs.
  const seedPairs = [];
  const seenPair = new Set();
  for (const key of directed) {
    const [a, b] = key.split('||');
    const rev = b + '||' + a;
    if (directed.has(rev)) {
      const pk = [a, b].sort().join('||');
      if (!seenPair.has(pk)) {
        seenPair.add(pk);
        seedPairs.push([a, b]);
      }
    }
  }

  // Expand each seed: add nodes connected to >=2 current members.
  const clusters = [];
  const usedSig = new Set();
  for (const seed of seedPairs) {
    const members = new Set(seed);
    let grew = true;
    while (grew && members.size < 5) {
      grew = false;
      // candidate set = union of neighbors of members not already in members
      const candCount = new Map();
      for (const m of members) {
        for (const nb of undirectedNeighbors.get(m)) {
          if (members.has(nb)) continue;
          candCount.set(nb, (candCount.get(nb) || 0) + 1);
        }
      }
      // pick best candidate connecting to >=2 members
      let best = null, bestC = 1;
      for (const [c, cnt] of candCount) {
        if (cnt >= 2 && cnt > bestC) { best = c; bestC = cnt; }
        else if (cnt >= 2 && cnt === bestC && best && c.localeCompare(best) < 0) best = c;
      }
      if (best) { members.add(best); grew = true; }
    }
    // count internal edges
    let edgeCount = 0;
    const arr = [...members];
    for (let i = 0; i < arr.length; i++) {
      for (let j = 0; j < arr.length; j++) {
        if (i === j) continue;
        if (directed.has(arr[i] + '||' + arr[j])) edgeCount++;
      }
    }
    const sig = arr.slice().sort().join('||');
    if (!usedSig.has(sig) && members.size >= 2) {
      usedSig.add(sig);
      clusters.push({ nodes: arr, edgeCount });
    }
  }
  clusters.sort((a, b) => b.edgeCount - a.edgeCount || b.nodes.length - a.nodes.length);
  let topClusters = clusters.slice(0, 10);

  // Fallback: this graph's dep edges are largely uni-directional, so bidirectional
  // seeding can yield nothing. When that happens, derive clusters by directory
  // co-location + mutual dependency density: group nodes that share a parent
  // directory AND have >=1 dep edge among them. These map to real subsystems
  // (Onboarding phases, Card Session, Desire Map, etc.).
  if (topClusters.length === 0) {
    const dirGroups = new Map(); // dir -> [ids]
    for (const n of nodes) {
      if (n.type !== 'file') continue;
      const fp = (n.filePath || '').replace(/\\/g, '/');
      const idx = fp.lastIndexOf('/');
      const dir = idx >= 0 ? fp.slice(0, idx) : '';
      if (!dirGroups.has(dir)) dirGroups.set(dir, []);
      dirGroups.get(dir).push(n.id);
    }
    const fallback = [];
    for (const [dir, ids] of dirGroups) {
      if (ids.length < 2) continue;
      // count internal dep edges within this directory group
      const idSet = new Set(ids);
      let edgeCount = 0;
      for (const a of ids) {
        for (const nb of undirectedNeighbors.get(a)) {
          if (idSet.has(nb)) edgeCount++;
        }
      }
      edgeCount = Math.floor(edgeCount / 2); // undirected double-count
      if (edgeCount >= 1) {
        // cap to 5 members, prefer highest fan-in members for representativeness
        const members = ids
          .slice()
          .sort((x, y) => (fanIn.get(y) || 0) - (fanIn.get(x) || 0) || x.localeCompare(y))
          .slice(0, 5);
        fallback.push({ nodes: members, edgeCount, dir });
      }
    }
    fallback.sort((a, b) => b.edgeCount - a.edgeCount || b.nodes.length - a.nodes.length);
    topClusters = fallback.slice(0, 10).map((c) => ({ nodes: c.nodes, edgeCount: c.edgeCount, dir: c.dir }));
  }

  // ---- Layers ----
  const layerOut = {
    count: layers.length,
    list: layers.map((l) => ({ id: l.id, name: l.name, description: l.description || '' }))
  };

  // ---- Node summary index (all node types) ----
  const nodeSummaryIndex = {};
  for (const n of nodes) {
    nodeSummaryIndex[n.id] = {
      name: n.name,
      type: n.type,
      filePath: n.filePath || '',
      summary: n.summary || ''
    };
  }

  const out = {
    scriptCompleted: true,
    entryPointCandidates,
    fanInRanking,
    fanOutRanking,
    bfsTraversal: {
      startNode: codeEntry,
      startNodeName: nameOf(codeEntry),
      order,
      depthMap,
      byDepth,
      reachedCount: order.length
    },
    nonCodeFiles,
    clusters: topClusters,
    layers: layerOut,
    nodeSummaryIndex,
    totalNodes: nodes.length,
    totalEdges: edges.length
  };

  try {
    fs.writeFileSync(outputPath, JSON.stringify(out, null, 2));
  } catch (e) {
    console.error('Failed to write output: ' + e.message);
    process.exit(1);
  }
  process.stderr.write(
    `OK: ${nodes.length} nodes, ${edges.length} edges. ` +
    `BFS start=${nameOf(codeEntry)} reached=${order.length}. ` +
    `clusters=${topClusters.length} docs=${nonCodeFiles.documentation.length} ` +
    `infra=${nonCodeFiles.infrastructure.length} data=${nonCodeFiles.data.length} ` +
    `config=${nonCodeFiles.config.length}\n`
  );
  process.exit(0);
}

main();
