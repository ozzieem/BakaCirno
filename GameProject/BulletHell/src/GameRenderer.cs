using System;
using System.Collections.Generic;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Audio;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;

namespace BulletHell
{
    /// <summary>
    ///     This is the main type for your game.
    /// </summary>
    public class BakaCirno : Game
    {
        public BakaCirno()
        {
            graphics = new GraphicsDeviceManager(this);
            Content.RootDirectory = "content";

            graphics.PreferredBackBufferWidth = 920;
            graphics.PreferredBackBufferHeight = 950;
        }

        protected override void Initialize()
        {
            //IsMouseVisible = true;
            base.Initialize();
        }

        protected override void LoadContent()
        {
            // Create a new SpriteBatch, which can be used to draw textures.
            spriteBatch = new SpriteBatch(GraphicsDevice);

            gameBackground = new Background(Content.Load<Texture2D>("../assets/textures/spacebgtemp"));
            menuBackground = new Background(Content.Load<Texture2D>("../assets/textures/mainbg2temp"));
            highScoreBackground = new Background(Content.Load<Texture2D>("../assets/textures/highscorebgtemp"));

            /* Music during playing had to be created as a Soundeffect since Monogame 
            was bugging with .wma-files and mp3.files */
            sound.Load(Content);
            GameMusic = sound.PlayingSong.CreateInstance();
            textOverlay.Load(Content);
            player.LoadPlayer(Content);
            //Enemies load in UpdateEnemies-function
        }

        protected override void UnloadContent()
        {
            // TODO: Unload any non ContentManager content here
        }

        protected override void Update(GameTime gameTime)
        {
            if (player.isDead)
            {
                GameState = State.GameOver;
            }

            // Activates music depending on GameState
            ActivateGameMusic();

            switch (GameState)
            {
                case State.Menu:
                {
                    player.Update(gameTime);
                    ResetGame();
                }
                    break;
                case State.Playing:
                {
                    player.Update(gameTime);
                    UpdateEnemies(gameTime);
                    UpdatePointBullets(gameTime);
                    UpdateExplosions(gameTime);
                    textOverlay.Update(gameTime);
                }
                    break;
                default:
                {
                }
                    break;
            }

            // Checks keyinput for selection 
            KeyShortcuts();

            base.Update(gameTime);
        }

        protected override void Draw(GameTime gameTime)
        {
            GraphicsDevice.Clear(Color.TransparentBlack);

            spriteBatch.Begin();
            {
                switch (GameState)
                {
                    case State.Menu:
                    {
                        menuBackground.Draw(spriteBatch);
                        player.Draw(spriteBatch);
                    }
                        break;
                    case State.Playing:
                    {
                        gameBackground.Draw(spriteBatch);
                        player.Draw(spriteBatch);
                        DrawListObjects();
                        textOverlay.Draw(spriteBatch);
                    }
                        break;
                    case State.GameOver:
                    {
                        highScoreBackground.Draw(spriteBatch);
                        highscores = new HighScoreText(textOverlay);
                        highscores.Load(Content);
                        highscores.Draw(spriteBatch);
                    }
                        break;
                    default:
                    {
                    }
                        break;
                }
            }
            spriteBatch.End();

            base.Draw(gameTime);
        }

        /// <summary>
        ///     Key-input Controller
        /// </summary>
        private void KeyShortcuts()
        {
            ks = Keyboard.GetState();

            // Returns user to menu if Esc-key is pressed
            if (ks.IsKeyDown(Keys.Escape))
            {
                GameState = State.Menu;
                ResetGame();

                // Exits game if Esc+F1-combination is pressed
                if (ks.IsKeyDown(Keys.F1))
                {
                    Exit();
                }
            }

            // Starts the game if Enter is pressed
            if (ks.IsKeyDown(Keys.Enter) && GameState == State.Menu)
            {
                if (!soundPlayed)
                {
                    sound.ButtonPlaySelect.Play(0.05f, 0f, 0f);
                    soundPlayed = true;
                }

                player.stopMovement = false;
                GameState = State.Playing;
            }

            // DEBUG
            // REMOVES ALL ENEMIES FROM THE CURRENT GAME
            if (ks.IsKeyDown(Keys.Delete))
            {
                try
                {
                    foreach (var enemy in enemies)
                    {
                        enemy.isVisible = false;
                    }
                }
                catch
                {
                }
            }
        }

        #region Properties

        public enum State
        {
            Menu,
            Playing,
            HighScore, //Highscore to be used in the future
            GameOver
        }

        private readonly GraphicsDeviceManager graphics;
        private SpriteBatch spriteBatch;
        private KeyboardState ks;
        private readonly Random random = new Random();

        private Background gameBackground;
        private Background menuBackground;
        private Background highScoreBackground;
        private readonly TextOverlay textOverlay = new TextOverlay();
        private HighScoreText highscores;
        private readonly Sound sound = new Sound();
        private SoundEffectInstance GameMusic;

        private readonly Player player = new Player();
        private readonly List<Enemy> enemies = new List<Enemy>(nEnemiesSpawn);
        private readonly List<Explosion> explosions = new List<Explosion>();
        private readonly List<PointBullet> points = new List<PointBullet>();

        private State GameState = State.Menu; //Initial State
        private const int nEnemiesSpawn = 4;
        private float _difficultyIncrease; // Increases bulletspeed for each enemy killed
        private bool soundPlayed;

        #endregion

        #region GameObjectFunctions

        /// <summary>
        ///     Resets Game-objects
        /// </summary>
        private void ResetGame()
        {
            player.position = new Vector2(425, 725);
            player.isColliding = false;
            player.isDead = false;
            player.soundPlayed = false;
            player.currentAnim = player.idleAnim;
            player.currentMilliSeconds = 0;

            player.bullets.Clear();
            enemies.Clear();
            points.Clear();

            _difficultyIncrease = 0;
            textOverlay.Score = 0;
            textOverlay.Time = 0;
            textOverlay.EnemiesKilled = 0;
            soundPlayed = false;
        }

        /// <summary>
        ///     Checks when Music is to be played
        /// </summary>
        private void ActivateGameMusic()
        {
            // Starts music
            if (!player.isDead && GameState == State.Playing)
            {
                GameMusic.Volume = 0.05f;
                GameMusic.Play();
            }

            // Stops music
            if (player.isColliding || player.isDead || GameState == State.Menu)
            {
                GameMusic.Pause();
            }
        }

        /// <summary>
        ///     Spawning Point-objects into the game
        /// </summary>
        public void SpawnPoints()
        {
            foreach (var enemy in enemies)
            {
                if (enemy.isVisible) continue;
                foreach (var cShots in enemy.circleShots)
                {
                    foreach (var bullet in cShots)
                    {
                        points.Add(new PointBullet(
                            Content.Load<Texture2D>("../assets/textures/pointBullethalfsize"),
                            bullet.position));

                        textOverlay.Score += 5;
                    }
                }
            }
        }

        /// <summary>
        ///     Collection of all updates for PointBullets
        /// </summary>
        /// <param name="gameTime"></param>
        public void UpdatePointBullets(GameTime gameTime)
        {
            foreach (var point in points)
            {
                point.Update(gameTime, player);
            }

            for (var i = 0; i < points.Count; i++)
            {
                if (points[i].isVisible) continue;
                textOverlay.Score += 10;
                points.RemoveAt(i);
                i--;
            }
        }

        public void UpdateExplosions(GameTime gameTime)
        {
            foreach (var explosion in explosions)
            {
                explosion.Load(Content);
                explosion.Update(gameTime);
            }

            for (var i = 0; i < explosions.Count; i++)
            {
                if (explosions[i].isVisible) continue;

                explosions.RemoveAt(i);
                i--;
            }
        }

        /// <summary>
        ///     Collection of all updates for Enemies
        /// </summary>
        /// <param name="gameTime"></param>
        public void UpdateEnemies(GameTime gameTime)
        {
            var enemyTextures = new[]
            {
                "../assets/textures/greenEnemy",
                "../assets/textures/redEnemy",
                "../assets/textures/yellowEnemy",
                "../assets/textures/blueEnemy"
            };

            // Used to randomize spawn position and enemytextures 
            var randX = random.Next(0, 750);
            var randY = random.Next(-200, -50);
            var enemyType = random.Next(0, enemyTextures.Length);

            foreach (var enemy in enemies)
            {
                enemy.Load(Content);
                enemy.Update(Content, gameTime, graphics, player);
            }

            // Adds enemies to the game according to nEnemiesSpawn value
            if (enemies.Count < nEnemiesSpawn)
            {
                enemies.Add(new Enemy(
                    Content.Load<Texture2D>(enemyTextures[enemyType]),
                    new Vector2(randX, randY), _difficultyIncrease));
            }

            for (var i = 0; i < enemies.Count; i++)
            {
                if (enemies[i].isVisible) continue;
                // Code below runs if enemy isnt Visible

                sound.EnemyDeath.Play(0.005f, 0.0f, 0.0f);

                // Increasing difficulty
                _difficultyIncrease += (float) 0.03;

                // Updating Text
                textOverlay.EnemiesKilled++;
                textOverlay.Score += 500;

                SpawnPoints(); // Spawns PointBullets
                explosions.Add(new Explosion(enemies[i].position));

                enemies.RemoveAt(i);
                i--;
            }
        }

        /// <summary>
        ///     Draws out all objects in Lists
        /// </summary>
        private void DrawListObjects()
        {
            foreach (var explosion in explosions)
            {
                explosion.Draw(spriteBatch);
            }

            foreach (var point in points)
            {
                point.Draw(spriteBatch);
            }

            foreach (var enemy in enemies)
            {
                enemy.Draw(spriteBatch);
            }
        }

        #endregion
    }
}