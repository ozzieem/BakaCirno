using System;
using System.Collections.Generic;
using System.Linq;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Content;
using Microsoft.Xna.Framework.Graphics;

namespace BakaCirno
{
    /// <summary>
    ///     Spawns bullets that fires in a snapshotted direction of the player, randomly scattered
    /// </summary>
    internal class RandomShots : List<Bullet>
    {
        public RandomShots(Vector2 position)
        {
            this.position = position;
            velocity = Vector2.Zero;
            isVisible = true;
        }

        public void Update(ContentManager content, GameTime gameTime,
            GraphicsDeviceManager graphics, Player player)
        {
            spawn += (float) gameTime.ElapsedGameTime.TotalSeconds;

            foreach (var bullet in this)
            {
                bullet.Update(gameTime, graphics.GraphicsDevice, player);
            }

            RandomPattern(content, player, gameTime);
        }

        public void Draw(SpriteBatch spriteBatch)
        {
            foreach (var bullet in this)
            {
                if (isVisible)
                {
                    bullet.Draw(spriteBatch);
                }
                else
                {
                    Remove(bullet);
                }
            }
        }

        /// <summary>
        ///     Shoots out Bullet-objects in a direction towards the player
        /// </summary>
        /// <param name="content"></param>
        /// <param name="player"></param>
        /// <param name="gameTime"></param>
        private void RandomPattern(ContentManager content, Player player, GameTime gameTime)
        {
            var colorIndex = random.Next(0, bulletColors.Length); //Bulletcolor
            var spawnPosX = (int) position.X;
            var spawnPosY = (int) position.Y;

            // Normalize allows objects to follow other objects
            difference = player.position - position;
            difference.Normalize();
            velocity.X += difference.X*(float) gameTime.ElapsedGameTime.TotalMilliseconds*0.1f;
            velocity.Y += 1f; // Moves downwards past players' x-position


            if (spawn >= 1) //Spawns every 1 second
            {
                spawn = 0;
                if (this.Count() < nBulletSpawn)
                {
                    Add(new Bullet(
                        content.Load<Texture2D>(bulletColors[colorIndex]),
                        new Vector2(spawnPosX, spawnPosY),
                        new Vector2(velocity.X, velocity.Y)/limitSpeed));
                }
            }
        }

        #region Properties

        private readonly Random random = new Random();

        private readonly string[] bulletColors =
        {
            "assets/textures/randomShot",
            "assets/textures/randomShot2",
            "assets/textures/randomShot3",
            "assets/textures/randomShot4"
        };

        public Vector2 position, difference, velocity;

        public int limitSpeed = 10;
        private readonly int nBulletSpawn = 1;
        private float spawn;
        public bool isVisible;

        #endregion
    }
}