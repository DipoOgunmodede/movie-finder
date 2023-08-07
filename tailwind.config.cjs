/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./index.html",
    "./src/**/*.{vue,js}"
  ],
  theme: {
    extend: {
      animation: {
        'spin-fast': 'spin 1s cubic-bezier(.71,-0.52,.28,1.41) infinite',
      }
  }},
  plugins: [],
}
