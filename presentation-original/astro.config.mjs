// @ts-check
import mdx from '@astrojs/mdx';
import { defineConfig } from 'astro/config';
import rehypeD2 from '@beoe/rehype-d2';
import rehypeStarryNight from '@microflash/rehype-starry-night'
import rehypeMathML from '@daiji256/rehype-mathml';
import remarkMath from 'remark-math';

export const rehypeD2Config = { layout: 'elk', theme: 1, pad: 0 }

// https://astro.build/config
export default defineConfig({
  base: '/nixos-full-source-bootstrap/presentation/original',
  markdown: {
    syntaxHighlight: false,
    remarkPlugins: [
      [remarkMath, {}]
    ],
    rehypePlugins: [
      [rehypeD2, rehypeD2Config],
      [rehypeMathML, {}],
      [rehypeStarryNight, {}],
    ]
  },
  integrations: [
    mdx({})
  ]
});
