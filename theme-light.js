const fs = require('fs');
const path = require('path');

const filePath = path.join(__dirname, 'index.html');
let content = fs.readFileSync(filePath, 'utf8');

// Replace CSS variables
content = content.replace(
  /--bg:#111116; --s1:#1A1A22; --s2:#22222C; --s3:#2C2C3A;\s*--text:#F0F0F0; --muted:#6B7280;/g,
  '--bg:#F9FAFB; --s1:#FFFFFF; --s2:#F3F4F6; --s3:#E5E7EB;\n      --text:#111827; --muted:#6B7280;'
);

// Replace rgba(255,255,255) with rgba(0,0,0) globally
content = content.replace(/rgba\(255,255,255,/g, 'rgba(0,0,0,');

// Replace topbar background
content = content.replace(
  /background:rgba\(17,17,22,\.97\)/g,
  'background:rgba(255,255,255,.97)'
);

// Replace .login-sub text color
content = content.replace(
  /color:rgba\(220,220,230,\.35\)/g,
  'color:rgba(17,17,22,.45)'
);

// Update login-card shadow
content = content.replace(
  /box-shadow:0 32px 80px rgba\(0,0,0,\.5\)/g,
  'box-shadow:0 32px 80px rgba(0,0,0,.15)'
);

// Update logo
content = content.replace(
  /src="\/logo-texpar\.png"/g,
  'src="./logo-texpar-preto.png"'
);

// Update Podium Hex Colors
content = content.replace(
  /1:\{bg:'#191300',border:li\.color\+'CC',glow:li\.color\+'44',badge:'#EF9F27',bt:'#0D0D0D'\}/g,
  "1:{bg:'#FFFBF0',border:li.color+'66',glow:li.color+'22',badge:'#EF9F27',bt:'#0D0D0D'}"
);
content = content.replace(
  /2:\{bg:'#141418',border:'#9CA3AF88',glow:'#9CA3AF22',badge:'#9CA3AF',bt:'#0D0D0D'\}/g,
  "2:{bg:'#F9FAFB',border:'#9CA3AF88',glow:'#9CA3AF22',badge:'#9CA3AF',bt:'#0D0D0D'}"
);
content = content.replace(
  /3:\{bg:'#160D08',border:'#CD7F3266',glow:'#CD7F3222',badge:'#CD7F32',bt:'#0D0D0D'\}/g,
  "3:{bg:'#FFF8F3',border:'#CD7F3266',glow:'#CD7F3222',badge:'#CD7F32',bt:'#0D0D0D'}"
);

fs.writeFileSync(filePath, content, 'utf8');
console.log('Theme updated successfully.');
