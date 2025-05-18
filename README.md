# ¿Quién es ese Pokémon?

Una aplicación móvil que recrea el clásico minijuego de los comerciales del anime Pokémon, donde los espectadores deben adivinar el nombre del Pokémon mostrado en silueta.

## Descripción

Este proyecto es una aplicación Flutter que simula el popular segmento "¿Quién es ese Pokémon?" del anime. La aplicación muestra la silueta de un Pokémon y el usuario debe adivinar su nombre. El juego incluye todas las generaciones de Pokémon desde Kanto hasta Paldea (1-9).

## Características

- **9 Generaciones Completas**: Adivina Pokémon desde Kanto hasta Paldea (1-9 generaciones).
- **Modo de Juego**: Visualiza la silueta de un Pokémon aleatorio e intenta adivinar su nombre.
- **Pokedéx Integrada**: Lleva un registro de los Pokémon que has capturado y los que se han escapado.
- **Sistema de Medallas**: Desbloquea medallas de gimnasio al capturar cierta cantidad de Pokémon.
- **Almacenamiento Local**: Tu progreso se guarda automáticamente en el dispositivo.
- **Efectos de Audio**: Disfruta de música y efectos de sonido del mundo Pokémon.

## Estructura del Proyecto

- **IMPORTS & CONSTANTS**: Librerías necesarias y definición de los rangos de cada generación Pokémon
- **APP INITIALIZATION**: Punto de inicio de la app con configuración del tema y pantalla principal
- **SPLASH SCREEN**: Pantalla de bienvenida con logo, audio y temporizador de 5 segundos
- **POKEMON GAME**: Juego principal donde adivinamos siluetas de Pokémon y guardamos nuestro progreso
- **POKEDEX SCREEN**: Pantalla que muestra todos nuestros Pokémon capturados y sistema de medallas

## Tecnologías Utilizadas

- **Flutter**: Framework de UI para desarrollo multiplataforma
- **Dart**: Lenguaje de programación
- **SharedPreferences**: Para almacenamiento local de datos del usuario
- **AudioPlayers**: Manejo de música y efectos de sonido
- **HTTP**: Para consumir la PokeAPI
- **API de Pokémon**: [PokeAPI](https://pokeapi.co/) para obtener datos e imágenes

## Instalación

1. Clona este repositorio:
   ```
   git clone https://github.com/fmarquezUDG/flutter_project.git
   ```

2. Navega al directorio del proyecto:
   ```
   cd flutter_project
   ```

3. Instala las dependencias:
   ```
   flutter pub get
   ```

4. Ejecuta la aplicación:
   ```
   flutter run
   ```

## Requisitos

- Flutter 3.0 o superior
- Conexión a Internet (para cargar imágenes desde la PokeAPI)

## Autor

Angel Francisco Sanchez de Tagle Marquez - Estudiante de Diseño de Aplicaciones Móviles en la Universidad de Guadalajara

## Agradecimientos

- Universidad de Guadalajara
- The Pokémon Company 
- Nintendo
- PokeAPI por proporcionar datos gratuitos sobre Pokémon

## Licencia

Este proyecto es con fines educativos únicamente. Pokémon y todos sus personajes son propiedad de Nintendo/Creatures Inc./GAME FREAK inc.
