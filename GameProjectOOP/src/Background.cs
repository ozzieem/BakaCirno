using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Content;
using Microsoft.Xna.Framework.Graphics;

namespace GameProjectOOP
{
    internal class Background
    {
        private readonly Vector2 backgroundPosition;
        private readonly Texture2D texture;

        public Background()
        {
            backgroundPosition = new Vector2(0, 0);
        }

        public Background(Texture2D texture)
        {
            this.texture = texture;
            backgroundPosition = new Vector2(0, 0);
        }

        public void Load(ContentManager content)
        {
            //texture = content.Load<Texture2D>("assets/extures/background");
        }

        public void Draw(SpriteBatch spriteBatch)
        {
            spriteBatch.Draw(texture, backgroundPosition, Color.White);
        }
    }
}