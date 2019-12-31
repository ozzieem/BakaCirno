using System;
using System.Collections.Generic;
using System.Linq;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Content;
using Microsoft.Xna.Framework.Graphics;

namespace BakaCirno
{
    /// <summary>
    ///     This class represents the circle-bulletpattern which spawns bullets of circles
    /// </summary>
    internal class CircleShots : List<Bullet>
    {
        private readonly string[] bulletColors =
        {
            "assets/textures/Blueshot1",
            "assets/textures/Redshot1",
            "assets/textures/Yellowshot1",
            "assets/textures/Greenshot1",
            "assets/textures/Purpleshot"
        };

        private readonly float circleSpeed = 2;
        private readonly Random random = new Random();
        public bool isVisible;

        public Vector2 position;

        private Sound sound = new Sound();
        private float spawn;
        public Vector2 velocity;

        public CircleShots(Vector2 pos, float speed)
        {
            position = pos;
            velocity = new Vector2(1, 1);
            isVisible = true;
            circleSpeed += speed;
        }

        public void Update(ContentManager content, GameTime gameTime,
            GraphicsDeviceManager graphics, Player player, Enemy enemy)
        {
            spawn += (float) gameTime.ElapsedGameTime.TotalSeconds;

            CheckCollision(gameTime, graphics, player);
            CirclePattern(content, gameTime, enemy);
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
        ///     Creates a new Bullet-object in the form of a circle
        /// </summary>
        /// <param name="content"></param>
        /// <param name="gameTime"></param>
        /// <param name="enemy"></param>
        private void CirclePattern(ContentManager content, GameTime gameTime, Enemy enemy)
        {
            const int spread = 360;
            const int degrees = 20;
            var circleSpawn = spawn;

            const float curveSizePerSecond = 0.1f;
            var curveAngle = (long) (gameTime.TotalGameTime.TotalMilliseconds/curveSizePerSecond)%degrees;

            var randBulletColor = random.Next(0, bulletColors.Length);

            for (var i = (int) curveAngle; i < spread + curveAngle; i += degrees)
            {
                if (!(circleSpawn >= 0)) continue;
                circleSpawn++;
                velocity.X = (float) -Math.Cos(MathHelper.ToRadians(i));
                velocity.Y = (float) Math.Sin(MathHelper.ToRadians(i));

                if (this.Count() >= spread/degrees) continue;
                Add(new Bullet(
                    content.Load<Texture2D>(bulletColors[randBulletColor]),
                    new Vector2(position.X + enemy.texture.Width/2, position.Y),
                    new Vector2(velocity.X, velocity.Y)*circleSpeed));
            }
        }

        private void CheckCollision(GameTime gameTime,
            GraphicsDeviceManager graphics, Player player)
        {
            foreach (var bullet in this)
            {
                bullet.Update(gameTime, graphics.GraphicsDevice, player);
                if (bullet.boundingBox.Intersects(player.bulletBoundingBox))
                {
                    player.isColliding = true;
                }
            }
        }
    }
}