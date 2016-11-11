using System;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace GameProjectOOP
{
    /// <summary>
    ///     The base class for the bullets in the game. Every bulletpattern uses this class
    /// </summary>
    internal class Bullet
    {
        public Rectangle boundingBox;
        public bool isVisible;
        public Vector2 position, velocity, origin;

        private Random random = new Random();
        public float RotationAngle;
        public float speed;
        public Texture2D texture;

        // Constructor
        public Bullet()
        {
        }

        public Bullet(Texture2D texture, Vector2 position, float speed)
        {
            this.texture = texture;
            this.position = position;
            this.speed = speed;
            isVisible = true;
        }

        public Bullet(Texture2D image, Vector2 position, Vector2 velocity)
        {
            texture = image;
            speed = 10;
            this.position = position;
            this.velocity = velocity;
            origin = new Vector2((float) texture.Width/2, (float) texture.Height/2);
            isVisible = true;
        }


        public void Update(GameTime gameTime, GraphicsDevice graphics, Player player)
        {
            CheckCollision(player);
            RotateBullet(gameTime);
            UpdateMovement();
            UpdateVisibility(graphics);
        }

        public void Draw(SpriteBatch spriteBatch)
        {
            //spriteBatch.Draw(texture, position, Color.White);
            spriteBatch.Draw(texture, position + new Vector2(35, 0), null,
                Color.White, RotationAngle, origin, 1.0f, SpriteEffects.None, 1f);
        }

        /// <summary>
        ///     Updates the image of the object and checks if outside the screen
        /// </summary>
        /// <param name="graphics"></param>
        private void UpdateVisibility(GraphicsDevice graphics)
        {
            boundingBox = new Rectangle(
                (int) position.X, (int) position.Y,
                texture.Width, texture.Height);

            // Remove bullet beyond visibility
            if (position.X < -20)
                isVisible = false;
            if (position.X >= graphics.Viewport.Bounds.Right)
                isVisible = false;
            if (position.X < 0 - texture.Height)
                isVisible = false;
            if (position.X < -10)
                isVisible = false;
        }

        /// <summary>
        ///     Moves the object
        /// </summary>
        private void UpdateMovement()
        {
            position += velocity;
        }

        /// <summary>
        ///     Rotates the object
        /// </summary>
        /// <param name="gameTime"></param>
        private void RotateBullet(GameTime gameTime)
        {
            var elapsed = (float) gameTime.ElapsedGameTime.TotalMilliseconds;

            RotationAngle += elapsed;
            var circle = MathHelper.Pi*2f;
            RotationAngle %= circle;
        }

        private void CheckCollision(Player player)
        {
            if (boundingBox.Intersects(player.bulletBoundingBox))
            {
                isVisible = false;
                player.isColliding = true;
            }
        }
    }
}