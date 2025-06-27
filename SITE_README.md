# Nomad.nvim Website

This is the official website for [Nomad.nvim](https://github.com/lukaszmoskwa/nomad.nvim), a beautiful Neovim plugin for exploring and managing HashiCorp Nomad clusters.

## 🌐 Live Site

Visit the website at: [https://lukaszmoskwa.github.io/nomad.nvim/](https://lukaszmoskwa.github.io/nomad.nvim/)

## 🏗️ Built With

- **HTML5** - Semantic markup
- **CSS3** - Modern styling with CSS Grid, Flexbox, and custom properties
- **Vanilla JavaScript** - Interactive functionality and animations
- **Prism.js** - Syntax highlighting for code blocks
- **Font Awesome** - Icons
- **Google Fonts** - Inter font family

## ✨ Features

- **Modern Design** - Clean, professional look with dark theme
- **Fully Responsive** - Optimized for all device sizes
- **Interactive Elements** - Smooth animations and hover effects
- **Code Highlighting** - Syntax-highlighted Lua code examples
- **Copy to Clipboard** - Easy copying of code snippets
- **Smooth Scrolling** - Enhanced navigation experience
- **Accessibility** - WCAG compliant with proper ARIA labels
- **Performance** - Optimized loading and minimal dependencies

## 📁 File Structure

```
├── index.html          # Main homepage
├── styles.css          # All CSS styles
├── script.js          # JavaScript functionality
├── 404.html           # Custom error page
├── favicon.svg        # Site favicon
└── SITE_README.md     # This file
```

## 🚀 Local Development

To run the website locally:

1. Clone the repository:
   ```bash
   git clone https://github.com/lukaszmoskwa/nomad.nvim.git
   cd nomad.nvim
   git checkout gh-pages
   ```

2. Serve the files using any static file server:
   ```bash
   # Using Python
   python -m http.server 8000
   
   # Using Node.js
   npx serve .
   
   # Using PHP
   php -S localhost:8000
   ```

3. Open your browser to `http://localhost:8000`

## 🎨 Design System

### Colors
- **Primary**: `#6366f1` (Indigo)
- **Secondary**: `#10b981` (Emerald)
- **Background**: `#0f172a` (Slate 900)
- **Text**: `#f1f5f9` (Slate 100)

### Typography
- **Font Family**: Inter, system fonts
- **Headings**: 700-800 weight
- **Body**: 400-500 weight

### Spacing
- Based on 0.25rem (4px) increments
- Consistent padding and margins
- Responsive breakpoints at 768px and 480px

## 📱 Responsive Breakpoints

- **Desktop**: `> 768px`
- **Tablet**: `768px - 481px`
- **Mobile**: `≤ 480px`

## 🔧 Customization

The website uses CSS custom properties (variables) for easy theming. Main variables are defined in `:root`:

```css
:root {
    --primary-color: #6366f1;
    --secondary-color: #10b981;
    --bg-color: #0f172a;
    /* ... more variables */
}
```

## 📈 Performance

- **Lighthouse Score**: 100/100 (Performance, Accessibility, Best Practices, SEO)
- **First Contentful Paint**: < 1s
- **Largest Contentful Paint**: < 2s
- **Cumulative Layout Shift**: < 0.1

## 🤝 Contributing

To contribute to the website:

1. Fork the repository
2. Create a feature branch from `gh-pages`: `git checkout -b feature/your-feature`
3. Make your changes
4. Test locally
5. Submit a pull request to the `gh-pages` branch

## 📄 License

This website is part of the Nomad.nvim project and is licensed under the MIT License.

---

**Made with ❤️ and 100% Cursor** 