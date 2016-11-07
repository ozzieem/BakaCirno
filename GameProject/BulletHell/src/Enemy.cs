using System;
using System.Collections.Generic;
using System.Linq;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Content;
using Microsoft.Xna.Framework.Graphics;

namespace BulletHell
{
    /// <summary>
    ///     The enemy class for enemy-objects which will be used in
    ///     a list in Game1.cs to spawn the objects
    /// </summary>
    internal class Enemy
    {
        public Enemy(Texture2D _texture, Vector2 _position, float nDeaths)
        {
            position = _position;
            texture = _texture;
            isVisible = true;
            shotDelay = maxShotDelay;
            enemyDeaths = nDeaths;

            //Number of circlespawns per enemy
            nCircleSpawns = random.Next(2, maxCircleSpawns);
            randX = random.Next(0, 750);
            randY = random.Next(-600, -50);
        }

        public void Load(ContentManager content)
        {
            boundingBox = new Rectangle(
                (int) position.X - 60, (int) position.Y,
                texture.Width*2, texture.Height);

            sound.Load(content);
        }

        public void Update(ContentManager content, GameTime gameTime,
            GraphicsDeviceManager graphics, Player player)
        {
            FollowPlayer(gameTime, player);
            CheckCollision(player);
            EnemyShot(gameTime);
            UpdateShots(content, gameTime, graphics, player);
            UpdateEnemy();
        }

        public void Draw(SpriteBatch spriteBatch)
        {
            if (isVisible)
            {
                spriteBatch.Draw(texture, sourceRect, Color.White);
            }

            foreach (var rBullet in randomBullets)
            {
                rBullet.Draw(spriteBatch);
            }

            foreach (var cBullet in circleShots)
            {
                cBullet.Draw(spriteBatch);
            }
        }

        /// <summary>
        ///     Updates Enemy-Texture
        /// </summary>
        private void UpdateEnemy()
        {
            sourceRect = new Rectangle(
                (int) position.X, (int) position.Y,
                texture.Width, texture.Height);

            boundingBox = new Rectangle(
                (int) position.X - 60, (int) position.Y,
                texture.Width*2, texture.Height);

            position.Y += enemySpeed;
            origin = new Vector2(position.X - 32, position.Y);

            if (position.Y >= 950)
            {
                isVisible = false;
            }
            if (health <= 0)
            {
                // Explosion is added in Game1-class
                isVisible = false;
                enemyDeaths++;
            }
        }

        /// <summary>
        ///     Updates the Enemy-shots
        /// </summary>
        /// <param name="content"></param>
        /// <param name="gameTime"></param>
        /// <param name="graphics"></param>
        /// <param name="player"></param>
        private void UpdateShots(ContentManager content, GameTime gameTime,
            GraphicsDeviceManager graphics, Player player)
        {
            foreach (var cBullet in circleShots)
            {
                cBullet.Update(content, gameTime, graphics, player, this);
            }
            for (var i = 0; i < circleShots.Count; ++i)
            {
                if (!circleShots[i].isVisible)
                {
                    circleShots.RemoveAt(i);
                    i--;
                }
            }

            foreach (var rBullet in randomBullets)
            {
                rBullet.Update(content, gameTime, graphics, player);
            }
            for (var i = 0; i < randomBullets.Count; ++i)
            {
                if (!randomBullets[i].isVisible)
                {
                    randomBullets.RemoveAt(i);
                    i--;
                }
            }
        }

        /// <summary>
        ///     Fires a shot every delay, and increases speed for CircleShots
        /// </summary>
        /// <param name="gameTime"></param>
        private void EnemyShot(GameTime gameTime)
        {
            speedIncrease += (float) gameTime.ElapsedGameTime.TotalSeconds*enemyDeaths;

            if (shotDelay >= 0)
            {
                shotDelay--;
            }

            if (shotDelay <= 0)
            {
                if (nCircleSpawns > 0)
                {
                    circleShots.Add(new CircleShots(origin, speedIncrease));

                    sound.EnemyCircleShoot.Play(0.005f, 0.0f, 0.0f);

                    nCircleSpawns--;
                }
                if (randomBullets.Count < maxRandomBullets)
                {
                    randomBullets.Add(new RandomShots(origin));

                    //sound.EnemyRandomShoot.Play(0.005f, 1.0f, 0.0f);

                    maxRandomBullets--;
                }
            }

            if (shotDelay == 0)
            {
                shotDelay = maxShotDelay;
            }
        }

        /// <summary>
        ///     Follows player x-position gradually
        /// </summary>
        /// <param name="gameTime"></param>
        /// <param name="player"></param>
        private void FollowPlayer(GameTime gameTime, Player player)
        {
            difference = player.position - position;
            difference.Normalize();
            position.X += difference.X*(float) gameTime.ElapsedGameTime.TotalMilliseconds*0.1f;
            position.Y += enemySpeed; // Moves past player downwards
        }

        private void CheckCollision(Player player)
        {
            if (position.Y >= 950) // Enemy gets removed if passed bottom of gamescreen
                isVisible = false;

            if (boundingBox.Intersects(player.bulletBoundingBox))
            {
                isVisible = false;
                player.isColliding = true;
            }

            for (var i = 0; i < player.bullets.Count; i++)
            {
                // Check if each fired bullet has passed enemy
                if (boundingBox.Intersects(player.bullets[i].boundingBox))
                {
                    if (player.powerShot) // Powershot by holding LEFTSHIFT
                    {
                        health -= 30;
                    }
                    else
                    {
                        health -= 10;
                    }

                    // Removes bullet if hit enemy
                    player.bullets.ElementAt(i).isVisible = false;
                }
            }
        }

        #region Properties

        public Texture2D texture;
        public Vector2 position, difference, origin;
        public Rectangle boundingBox;
        private Rectangle sourceRect;
        public List<RandomShots> randomBullets = new List<RandomShots>();
        public List<CircleShots> circleShots = new List<CircleShots>();
        private readonly Random random = new Random();

        public int shotDelay;
        public int nCircleSpawns;
        private int maxRandomBullets = 10; // Maxnumber of randomBulletsspawns per enemy
        public const int maxShotDelay = 100; // Decides how often shots are to be fired
        private const int maxCircleSpawns = 5; // Maxnumber of Circleshots per enemy

        private float speedIncrease;
        private float enemyDeaths;
        public float enemySpeed = 0.5f;
        public float randX, randY;
        public float health = 100;

        public bool isVisible;

        private readonly Sound sound = new Sound();

        #endregion
    }
}