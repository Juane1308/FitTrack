import fs from 'node:fs/promises';
import path from 'node:path';

import { getPrismaClient } from '../src/config/database.js';

const args = process.argv.slice(2);

function argument(name) {
  const index = args.indexOf(name);
  return index >= 0 ? args[index + 1] : null;
}

function mimeType(filePath) {
  const extension = path.extname(filePath).toLowerCase();
  return {
    '.jpg': 'image/jpeg',
    '.jpeg': 'image/jpeg',
    '.png': 'image/png',
    '.webp': 'image/webp',
  }[extension] ?? null;
}

const assetKey = argument('--key');
const filePath = argument('--file');
const contentType = filePath ? mimeType(filePath) : null;

if (!assetKey || !filePath || !contentType) {
  console.error('Uso: node scripts/upload-media-assets.js --key nombre-clave --file "ruta\\imagen"');
  process.exit(1);
}

const prisma = getPrismaClient();

try {
  const imageData = await fs.readFile(filePath);
  await prisma.mediaAsset.upsert({
    where: { assetKey },
    create: { assetKey, mimeType: contentType, imageData },
    update: { mimeType: contentType, imageData },
  });
  console.log(`Imagen ${assetKey} guardada en PostgreSQL (${imageData.length} bytes).`);
} finally {
  await prisma.$disconnect();
}
