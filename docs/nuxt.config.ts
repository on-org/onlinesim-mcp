import { readdirSync } from 'node:fs'

const repo = 'onlinesim-mcp'
const docsBase = process.env.NUXT_APP_BASE_URL || (process.env.NODE_ENV === 'production' ? `/${repo}/` : '/')

/** Every content page, so prerender does not depend on link crawling alone. */
const pageRoutes = readdirSync(new URL('./content', import.meta.url))
  .filter((file) => file.endsWith('.md'))
  .map((file) => (file === 'index.md' ? '/' : `/${file.slice(0, -'.md'.length)}`))

export default defineNuxtConfig({
  modules: ['@nuxt/ui', '@nuxt/content', 'nuxt-llms'],

  css: ['~/assets/css/main.css'],

  app: {
    baseURL: docsBase,
    head: {
      htmlAttrs: { lang: 'en' },
      link: [{ rel: 'icon', type: 'image/svg+xml', href: `${docsBase}favicon.svg` }],
    },
  },

  icon: {
    // Bundle every rendered icon: the static host never falls back to the Iconify API.
    clientBundle: {
      scan: true,
      icons: ['simple-icons:github', 'simple-icons:rust', 'lucide:terminal', 'lucide:download', 'lucide:file-json'],
      sizeLimitKb: 256,
    },
  },

  colorMode: {
    preference: 'system',
  },

  content: {
    build: {
      markdown: {
        toc: { searchDepth: 2 },
        highlight: { langs: ['bash', 'powershell', 'json', 'toml'] },
      },
    },
    experimental: {
      sqliteConnector: 'native',
    },
  },

  nitro: {
    prerender: {
      // `tools.html`, not `tools/index.html`: GitHub Pages serves `/tools` without a redirect.
      autoSubfolderIndex: false,
      crawlLinks: true,
      failOnError: true,
      routes: pageRoutes,
    },
  },

  llms: {
    domain: `https://on-org.github.io/${repo}`,
    title: 'onlinesim-mcp',
    description: 'Local MCP server (Streamable HTTP) and CLI for OnlineSim: order receive-only numbers and read SMS from AI agents.',
    sections: [
      {
        title: 'Documentation',
        contentCollection: 'docs',
        contentFilters: [{ field: 'extension', operator: '=', value: 'md' }],
      },
    ],
    full: {
      title: 'onlinesim-mcp — full docs',
      description: 'Complete documentation of the OnlineSim MCP server and CLI.',
    },
  },

  compatibilityDate: '2025-11-03',
})
