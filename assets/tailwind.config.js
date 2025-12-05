// See the Tailwind configuration guide for advanced usage
// https://tailwindcss.com/docs/configuration

const plugin = require("tailwindcss/plugin")
const fs = require("fs")
const path = require("path")

module.exports = {
  darkMode: 'class',
  content: [
    "./js/**/*.js",
    "../lib/adminex_docker_web.ex",
    "../lib/adminex_docker_web/**/*.*ex"
  ],
  theme: {
    extend: {
      colors: {
        // Elixir Purple Theme
        primary: {
          DEFAULT: '#4e2a8e',
          light: '#7d56c2',
          dark: '#3b1f6e',
          50: '#f5f0ff',
          100: '#ede5ff',
          200: '#d499ff',
          300: '#b77dff',
          400: '#9b5de5',
          500: '#7d56c2',
          600: '#4e2a8e',
          700: '#3b1f6e',
          800: '#2d1854',
          900: '#1a0f33',
        },
        accent: {
          DEFAULT: '#d499ff',
          light: '#e6c2ff',
          dark: '#b77dff',
        },
        // Background colors
        surface: {
          light: '#f8f7fa',
          dark: '#0f0b15',
        },
        card: {
          light: '#ffffff',
          dark: '#1a1625',
        },
      },
      backgroundImage: {
        'gradient-elixir': 'linear-gradient(135deg, #4e2a8e 0%, #7d56c2 100%)',
        'gradient-elixir-dark': 'linear-gradient(135deg, #7d56c2 0%, #a66cc3 100%)',
        'gradient-accent': 'linear-gradient(135deg, #7d56c2 0%, #d499ff 100%)',
      },
      boxShadow: {
        'elixir': '0 10px 40px rgba(78, 42, 142, 0.15)',
        'elixir-lg': '0 20px 60px rgba(78, 42, 142, 0.2)',
        'glow': '0 0 20px rgba(125, 86, 194, 0.4)',
        'glow-lg': '0 0 40px rgba(125, 86, 194, 0.5)',
      },
      animation: {
        'glow-pulse': 'glow-pulse 2s ease-in-out infinite',
      },
      keyframes: {
        'glow-pulse': {
          '0%, 100%': { boxShadow: '0 0 20px rgba(125, 86, 194, 0.4)' },
          '50%': { boxShadow: '0 0 30px rgba(125, 86, 194, 0.6)' },
        },
      },
    },
  },
  plugins: [
    require("@tailwindcss/forms"),
    // Allows prefixing tailwind classes with LiveView classes to add rules
    // only when LiveView classes are applied, for example:
    //
    //     <div class="phx-click-loading:animate-ping">
    //
    plugin(({addVariant}) => addVariant("phx-click-loading", [".phx-click-loading&", ".phx-click-loading &"])),
    plugin(({addVariant}) => addVariant("phx-submit-loading", [".phx-submit-loading&", ".phx-submit-loading &"])),
    plugin(({addVariant}) => addVariant("phx-change-loading", [".phx-change-loading&", ".phx-change-loading &"])),

    // Embeds Heroicons (https://heroicons.com) into your app.css bundle
    // See your `CoreComponents.icon/1` for more information.
    //
    plugin(function({matchComponents, theme}) {
      let iconsDir = path.join(__dirname, "../deps/heroicons/optimized")
      let values = {}
      let icons = [
        ["", "/24/outline"],
        ["-solid", "/24/solid"],
        ["-mini", "/20/solid"],
        ["-micro", "/16/solid"]
      ]
      icons.forEach(([suffix, dir]) => {
        fs.readdirSync(path.join(iconsDir, dir)).forEach(file => {
          let name = path.basename(file, ".svg") + suffix
          values[name] = {name, fullPath: path.join(iconsDir, dir, file)}
        })
      })
      matchComponents({
        "hero": ({name, fullPath}) => {
          let content = fs.readFileSync(fullPath).toString().replace(/\r?\n|\r/g, "")
          let size = theme("spacing.6")
          if (name.endsWith("-mini")) {
            size = theme("spacing.5")
          } else if (name.endsWith("-micro")) {
            size = theme("spacing.4")
          }
          return {
            [`--hero-${name}`]: `url('data:image/svg+xml;utf8,${content}')`,
            "-webkit-mask": `var(--hero-${name})`,
            "mask": `var(--hero-${name})`,
            "mask-repeat": "no-repeat",
            "background-color": "currentColor",
            "vertical-align": "middle",
            "display": "inline-block",
            "width": size,
            "height": size
          }
        }
      }, {values})
    })
  ]
}
