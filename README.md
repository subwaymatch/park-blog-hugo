<p align="center">
  <a href="https://park.is">
    <img src="https://user-images.githubusercontent.com/1064036/85344966-c0ce1400-b4b6-11ea-8841-3498fbc0d1b1.png" alt="Park Logo" width="300" />
  </a>
  <br /><br />
  <a href="https://app.netlify.com/sites/park-blog/deploys">
    <img src="https://api.netlify.com/api/v1/badges/509e708b-909e-49d7-a6cf-eeed6fe0d935/deploy-status" alt="Netlify Deploy Status Badge" width="200" />
  </a>
</p>

# Park Blog

A personal blog built with [Hugo](https://gohugo.io/). The main goal of this blog is to use Jupyter notebooks as a blogging source without fancy converters: Jupyter's [nbconvert](https://github.com/jupyter/nbconvert) turns notebooks into HTML fragments that Hugo renders with a dedicated layout.

## Requirements

- [Hugo](https://gohugo.io/installation/) 0.158 or newer (the standard build is enough; the theme uses plain CSS, so no Sass is needed).
- [nbconvert](https://nbconvert.readthedocs.io/) (`pip install nbconvert`), only when converting notebooks.

## Development

```sh
hugo server -D     # live-reloading dev server, including drafts
hugo --gc --minify # production build into public/
```

## Writing

### Blog posts

```sh
hugo new content blog_posts/YYYYMMDD_my_post.md
```

Front matter supports `title`, `date`, `draft`, `categories`, and `math: true` to load MathJax for a post that contains LaTeX.

### Jupyter notebooks

1. Put the notebook in `content/notebooks/`.
2. Run `scripts/convert-notebooks.sh` (optionally with specific `.ipynb` paths). It writes a sibling `.html` file for each notebook.
3. Provide the front matter (`title`, `date`, `categories`) in one of two ways:
   - as a **raw cell** at the top of the notebook containing the YAML block (nbconvert copies it verbatim), or
   - by editing the top of the generated `.html` file. The script keeps that block on later re-runs.

   New notebooks without either get a `draft: true` stub to fill in.

Notebook pages load require.js and MathJax automatically so that interactive outputs (Plotly, Vega/Altair) and equations render.

## Project layout

```
content/blog_posts/   Markdown posts
content/notebooks/    Jupyter notebooks (.ipynb) and their converted .html twins
themes/park-blog-theme/
  layouts/            Hugo templates (baseof, home, list, page, notebooks/page, _partials)
  assets/css/         Plain CSS (reset, main, hamburger, jupyter), bundled and fingerprinted by Hugo Pipes
  assets/js/          Menu toggle
static/images/        Logo and favicons
scripts/              Notebook conversion script
hugo.toml             Site configuration
netlify.toml          Netlify build settings (pins the Hugo version)
```

## Notes

- [Inter](https://rsms.me/inter/) font family is used for sans-serif text.
- [Freight Text Pro](https://fonts.adobe.com/fonts/freight-text) from [Adobe Fonts](https://fonts.adobe.com/) is used for serif text (paid font, loaded from Typekit).
- Google Analytics 4 is configured through `services.googleAnalytics.id` in `hugo.toml`. Hugo only emits the tag in production builds.
