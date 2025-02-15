<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>GTA V Online Font Example</title>
  <style>
    /* 1) Define the custom font */
    @font-face {
      font-family: 'Pricedown';
      src: url('path-to-your-font/Pricedown.ttf') format('truetype');
    }

    /* 2) Create a CSS class for the GTA style text */
    .gta-font {
      font-family: 'Pricedown', sans-serif; /* Fallback to sans-serif if the custom font fails */
      color: #0078D7;       /* Windows 11 Blue */
      font-weight: bold;    /* Bold */
      font-style: italic;   /* Slanted/Italic */
    }

    /* Centering the text (optional) */
    h1 {
      text-align: center;
    }
    p {
      text-align: center;
    }
  </style>
</head>
<body>

  <!-- 3) Use the class on your text -->
  <h1>
    PC <span class="gta-font">Toolkit</span> windows
  </h1>
  <p>Programs, Tools and Modifications, Plugins for a better Windows for gamers.</p>

</body>
</html>
