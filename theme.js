/* ==========================================================================
   DJ·World — Tailwind-koppeling
   --------------------------------------------------------------------------
   Vertaalt de variabelen uit theme.css naar Tailwind-klassennamen.
   Hier staan GEEN kleurwaardes: die horen in theme.css.

   Let op de volgorde in de <head> van elke pagina:
       <script src="https://cdn.tailwindcss.com"></script>   <- eerst
       <link rel="stylesheet" href="theme.css">
       <script src="theme.js"></script>                      <- daarna
   Tailwind moet er al zijn voordat we zijn configuratie zetten.

   Beschikbare klassen:
       bg-ink  bg-sunken  bg-card  bg-line        (en border- / text- varianten)
       bg-brand  hover:bg-brand-dark  text-brand  accent-brand
   Doorzichtigheid werkt gewoon:  bg-line/50, bg-brand/15, bg-ink/95
   ========================================================================== */

tailwind.config = {
  theme: {
    extend: {

      colors: {
        /* Vlakken en merk */
        ink:    'rgb(var(--ink-rgb) / <alpha-value>)',
        sunken: 'rgb(var(--sunken-rgb) / <alpha-value>)',
        card:   'rgb(var(--card-rgb) / <alpha-value>)',
        line:   'rgb(var(--line-rgb) / <alpha-value>)',
        brand: {
          DEFAULT: 'rgb(var(--brand-rgb) / <alpha-value>)',
          dark:    'rgb(var(--brand-dark-rgb) / <alpha-value>)',
        },

        /* Tekstkleuren. De bestaande klassen text-white en text-gray-300 t/m
           700 wijzen nu naar theme.css, zodat we ze niet in 15 bestanden
           hoefden te hernoemen. De rest van de gray-schaal blijft standaard. */
        white: 'rgb(var(--fg-rgb) / <alpha-value>)',
        gray: {
          300: 'rgb(var(--fg-2-rgb) / <alpha-value>)',
          400: 'rgb(var(--fg-3-rgb) / <alpha-value>)',
          500: 'rgb(var(--fg-4-rgb) / <alpha-value>)',
          600: 'rgb(var(--fg-5-rgb) / <alpha-value>)',
          700: 'rgb(var(--fg-6-rgb) / <alpha-value>)',
        },
      },

      /* rounded-lg / -xl / -2xl volgen nu theme.css */
      borderRadius: {
        lg:    'var(--radius-lg)',
        xl:    'var(--radius-xl)',
        '2xl': 'var(--radius-2xl)',
      },

      /* De standaardduur van elke transition, plus duration-300 / duration-500 */
      transitionDuration: {
        DEFAULT: 'var(--motion-base)',
        300:     'var(--motion-slow)',
        500:     'var(--motion-slower)',
      },

      fontFamily: {
        sans: 'var(--font-sans)',
        mono: 'var(--font-mono)',
      },
    },
  },
}
