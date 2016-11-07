using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace BulletHell
{
    /// <summary>
    ///     The class for the points that fall towards the player when enemies are beaten.
    ///     Spawns on the current location of the bullets.
    ///     Almost like the Bullet class, except with different behaviour.
    /// </summary>
    internal class PointBullet
    {
        private readonly Texture2D texture;
        private Rectangle boundingBox;
        private Vector2 difference;

        public bool isVisible = true;
        public Vector2 position;

        public PointBullet(Texture2D texture, Vector2 position)
        {
            this.texture = texture;
            this.position = position;
            boundingBox = new Rectangle(
                (int) this.position.X, (int) this.position.Y,
                this.texture.Width, this.texture.Height);
        }

        public void Draw(SpriteBatch spriteBatch)
        {
            if (isVisible)
            {
                spriteBatch.Draw(texture, position, Color.White);
            }
        }

        public void Update(GameTime gametime, Player player)
        {
            MoveToPlayer(gametime, player);
            RemoveAtPlayer(player);

            boundingBox = new Rectangle((int) position.X, (int) position.Y,
                texture.Width*5, texture.Height*5);
        }

        /// <summary>
        ///     Object moves towards player
        /// </summary>
        /// <param name="gameTime"></param>
        /// <param name="player"></param>
        private void MoveToPlayer(GameTime gameTime, Player player)
        {
            difference = player.position - position;
            difference.Normalize();
            position.X += difference.X*(float) gameTime.ElapsedGameTime.TotalMilliseconds;
            position.Y += difference.Y*30;
        }

        /// <summary>
        ///     Object gets removed upon intersecting with players' boundingbox
        /// </summary>
        /// <param name="player"></param>
        private void RemoveAtPlayer(Player player)
        {
            // Remove when arriving at player
            if (boundingBox.Intersects(player.pointBoundingBox))
            {
                isVisible = false;
            }
        }
    }
}