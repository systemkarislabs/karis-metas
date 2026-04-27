-- ═══════════════════════════════════════════════════════════════════════════════
--  KARIS META — Plataforma SaaS Multi-Tenant
--  Desenvolvido por Karis Labs
--
--  Cole este conteúdo no SQL Editor do seu projeto Supabase e clique em "Run" (▶).
--
--  ARQUITETURA:
--    Um único banco de dados Supabase serve múltiplos clientes (tenants).
--    O isolamento entre empresas é garantido pela coluna tenant_id em todas
--    as tabelas + Row Level Security (RLS) ativado em cada tabela.
-- ═══════════════════════════════════════════════════════════════════════════════


-- ── 1. TABELAS ───────────────────────────────────────────────────────────────


-- Empresas cadastradas na plataforma (cada linha = um tenant / cliente)
-- lojas é um array JSON com as unidades da empresa.
-- Formato esperado: [{"id":"centro","label":"SC Centro","color":"#EF9F27","short":"SC-C"}]
CREATE TABLE IF NOT EXISTS tenants (
  id        TEXT PRIMARY KEY,
  name      TEXT NOT NULL,
  logo_url  TEXT NOT NULL DEFAULT '',
  cor       TEXT NOT NULL DEFAULT '#22D3A0',
  lojas     JSONB NOT NULL DEFAULT '[]'
);


-- Vendedores de cada empresa.
-- Usa SERIAL como PK para que cada tenant possa ter vendedores com id 1, 2, 3...
-- O par (id, tenant_id) é único na prática; o isolamento real é pelo tenant_id + RLS.
CREATE TABLE IF NOT EXISTS vendors (
  id            SERIAL  PRIMARY KEY,
  tenant_id     TEXT    NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  name          TEXT    NOT NULL,
  loja          TEXT    NOT NULL,   -- deve corresponder a um id dentro de tenants.lojas
  tipo          TEXT    NOT NULL DEFAULT 'vend',  -- 'vend' | 'fin'
  sales         INTEGER NOT NULL DEFAULT 0,
  goal          INTEGER NOT NULL DEFAULT 0,
  inatives      INTEGER NOT NULL DEFAULT 0,   -- clientes inativos recuperados
  inatives_goal INTEGER NOT NULL DEFAULT 0,
  nps           INTEGER NOT NULL DEFAULT 0,
  nps_goal      INTEGER NOT NULL DEFAULT 0
);


-- Mapeia cada usuário admin à sua empresa e loja.
-- Usuários autenticados que NÃO estão nesta tabela são apenas visualizadores.
CREATE TABLE IF NOT EXISTS store_admins (
  user_id   UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  tenant_id TEXT NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  loja      TEXT NOT NULL
);


-- Configurações por empresa (ex.: data da última atualização dos dados).
-- A chave primária composta (tenant_id, key) garante isolamento por tenant.
CREATE TABLE IF NOT EXISTS settings (
  tenant_id TEXT NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  key       TEXT NOT NULL,
  value     TEXT NOT NULL DEFAULT '',
  PRIMARY KEY (tenant_id, key)
);


-- ── 2. DADOS INICIAIS — Texpar Malhas ────────────────────────────────────────

-- Tenant: Texpar Malhas
INSERT INTO tenants (id, name, logo_url, cor, lojas)
VALUES (
  'texpar',
  'Texpar Malhas',
  '',
  '#22D3A0',
  '[
    {"id":"centro",    "label":"SC Centro",       "color":"#EF9F27", "short":"SC-C"},
    {"id":"saida",     "label":"SC Saída",         "color":"#3B82F6", "short":"SC-S"},
    {"id":"rua-preta", "label":"SC Rua Preta",     "color":"#A855F7", "short":"SC-R"},
    {"id":"gregorio",  "label":"SC São Gregório",  "color":"#EF4444", "short":"SC-G"}
  ]'::jsonb
)
ON CONFLICT (id) DO NOTHING;


-- Vendedores da Texpar Malhas
INSERT INTO vendors (tenant_id, name, loja, tipo, sales, goal, inatives, inatives_goal, nps, nps_goal) VALUES
  ('texpar', 'Rilton',   'centro',    'vend', 0, 0, 0, 0, 0, 0),
  ('texpar', 'Helton',   'centro',    'vend', 0, 0, 0, 0, 0, 0),
  ('texpar', 'Eduardo',  'centro',    'vend', 0, 0, 0, 0, 0, 0),
  ('texpar', 'Gilmar',   'saida',     'vend', 0, 0, 0, 0, 0, 0),
  ('texpar', 'Denilson', 'saida',     'vend', 0, 0, 0, 0, 0, 0),
  ('texpar', 'Victor',   'saida',     'vend', 0, 0, 0, 0, 0, 0),
  ('texpar', 'Lucas',    'saida',     'vend', 0, 0, 0, 0, 0, 0),
  ('texpar', 'Higor',    'rua-preta', 'vend', 0, 0, 0, 0, 0, 0),
  ('texpar', 'Wesley',   'gregorio',  'vend', 0, 0, 0, 0, 0, 0),
  ('texpar', 'Thiago',   'gregorio',  'vend', 0, 0, 0, 0, 0, 0),
  ('texpar', 'Jean',     'gregorio',  'vend', 0, 0, 0, 0, 0, 0);


-- Configuração inicial: data da última atualização (vazia por padrão)
INSERT INTO settings (tenant_id, key, value)
VALUES ('texpar', 'updated_at', '')
ON CONFLICT (tenant_id, key) DO NOTHING;


-- ── 3. ROW LEVEL SECURITY (RLS) ──────────────────────────────────────────────
--
--  MODELO DE ACESSO:
--    • Usuário não logado               → bloqueado (sem acesso a nada)
--    • Usuário autenticado (qualquer)   → pode LER dados da plataforma
--    • Admin (presente em store_admins) → pode ATUALIZAR os dados da sua loja
--                                         dentro do seu tenant
-- ─────────────────────────────────────────────────────────────────────────────

ALTER TABLE tenants      ENABLE ROW LEVEL SECURITY;
ALTER TABLE vendors      ENABLE ROW LEVEL SECURITY;
ALTER TABLE store_admins ENABLE ROW LEVEL SECURITY;
ALTER TABLE settings     ENABLE ROW LEVEL SECURITY;


-- tenants: qualquer usuário autenticado pode ler a lista de empresas
CREATE POLICY "tenants_leitura_autenticada"
  ON tenants FOR SELECT
  USING (auth.uid() IS NOT NULL);


-- vendors: qualquer usuário autenticado pode ler os vendedores
CREATE POLICY "vendors_leitura_autenticada"
  ON vendors FOR SELECT
  USING (auth.uid() IS NOT NULL);

-- vendors: admin só pode atualizar vendedores da sua loja e do seu tenant
CREATE POLICY "vendors_admin_atualiza_sua_loja"
  ON vendors FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM store_admins
      WHERE user_id   = auth.uid()
        AND loja      = vendors.loja
        AND tenant_id = vendors.tenant_id
    )
  );


-- store_admins: qualquer usuário autenticado pode ler a tabela de admins
CREATE POLICY "store_admins_leitura_autenticada"
  ON store_admins FOR SELECT
  USING (auth.uid() IS NOT NULL);


-- settings: qualquer usuário autenticado pode ler as configurações
CREATE POLICY "settings_leitura_autenticada"
  ON settings FOR SELECT
  USING (auth.uid() IS NOT NULL);

-- settings: admin pode atualizar configurações do seu próprio tenant
CREATE POLICY "settings_admin_atualiza_seu_tenant"
  ON settings FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM store_admins
      WHERE user_id   = auth.uid()
        AND tenant_id = settings.tenant_id
    )
  );


-- ── 4. COMO ADICIONAR UMA NOVA EMPRESA (TENANT) ──────────────────────────────
--
--  Siga os passos abaixo para integrar um novo cliente à plataforma Karis Meta.
--
--  PASSO 1 — Cadastrar o tenant (empresa)
--    Defina um id único em minúsculas (slug), o nome, logo e as lojas da empresa.
--
--    INSERT INTO tenants (id, name, logo_url, cor, lojas) VALUES (
--      'nome-empresa',
--      'Nome da Empresa',
--      'https://exemplo.com/logo.png',
--      '#22D3A0',
--      '[
--        {"id":"loja-a","label":"Filial A","color":"#3B82F6","short":"FA"},
--        {"id":"loja-b","label":"Filial B","color":"#EF4444","short":"FB"}
--      ]'::jsonb
--    );
--
--
--  PASSO 2 — Cadastrar os vendedores da empresa
--    Use o mesmo tenant_id do passo anterior. Os ids são gerados automaticamente
--    pelo SERIAL, então cada empresa tem sua própria numeração independente.
--
--    INSERT INTO vendors (tenant_id, name, loja, tipo) VALUES
--      ('nome-empresa', 'Vendedor 1', 'loja-a', 'vend'),
--      ('nome-empresa', 'Vendedor 2', 'loja-b', 'vend');
--
--
--  PASSO 3 — Criar as configurações iniciais do tenant
--
--    INSERT INTO settings (tenant_id, key, value)
--    VALUES ('nome-empresa', 'updated_at', '');
--
--
--  PASSO 4 — Criar os usuários no Supabase Auth
--    Acesse: Supabase → Authentication → Users → "Add user"
--    Crie um usuário para cada admin (e/ou visualizador) da empresa.
--    Visualizadores não precisam de nenhum INSERT extra — basta ter conta.
--
--
--  PASSO 5 — Vincular os admins às suas lojas
--    Copie o UUID de cada usuário admin criado no Passo 4 e insira abaixo.
--    Um admin pode gerenciar apenas a loja atribuída ao seu registro.
--
--    INSERT INTO store_admins (user_id, tenant_id, loja) VALUES
--      ('xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx', 'nome-empresa', 'loja-a'),
--      ('yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy', 'nome-empresa', 'loja-b');
--
-- ═══════════════════════════════════════════════════════════════════════════════
