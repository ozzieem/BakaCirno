using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Content;
using Microsoft.Xna.Framework.Graphics;

namespace GameProjectOOP
{
    /// <summary>
    ///     Explosion class mainly for enemies at the moment
    /// </summary>
    internal class Explosion
    {
        private readonly int frameWidth;
        private int currentFrame;

        public float elapsed, animationDelay;
        public bool isVisible;
        public Vector2 position;
        public Rectangle sourceRect;
        public Texture2D texture;

        public Explosion(Vector2 position)
        {
            // Position pruning to line up with enemy-position
            this.position = new Vector2(position.X - 40, position.Y - 35);
            elapsed = 0f;
            animationDelay = 30f;
            currentFrame = 1;
            frameWidth = 134;
            isVisible = true;
        }

        public void Load(ContentManager content)
        {
            texture = content.Load<Texture2D>("assets/textures/EnemyExplosion");
        }

        /// <summary>
        ///     Updates the sprites for each frame on the same position
        /// </summary>
        /// <param name="gameTime"></param>
        public void Update(GameTime gameTime)
        {
            elapsed += (float) gameTime.ElapsedGameTime.TotalMilliseconds;

            if (elapsed >= animationDelay)
            {
                currentFrame++;
                elapsed = 0f;
            }

            if (currentFrame == 10)
            {
                isVisible = false;
                currentFrame = 0;
            }

            sourceRect = new Rectangle(frameWidth*currentFrame, 0, frameWidth, texture.Height);
        }

        public void Draw(SpriteBatch spriteBatch)
        {
            if (isVisible)
                spriteBatch.Draw(texture, position, sourceRect, Color.White);
        }
    }
}