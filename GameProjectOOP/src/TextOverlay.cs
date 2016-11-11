using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Content;
using Microsoft.Xna.Framework.Graphics;

namespace GameProjectOOP
{
    internal class TextOverlay
    {
        private SpriteFont _font;

        public Vector2
            ScorePosition,
            TimePosition,
            EnemiesKilledPosition,
            ControlInfoPosition,
            InfoPosition;

        public float Time, EnemiesKilled, Score;

        public TextOverlay()
        {
            Score = 0;
            Time = 0;
            EnemiesKilled = 0;
        }

        public void Load(ContentManager content)
        {
            _font = content.Load<SpriteFont>("assets/fonts/Font");

            ScorePosition = new Vector2(0, 100);
            TimePosition = new Vector2(0, 130);
            EnemiesKilledPosition = new Vector2(0, 150);
            ControlInfoPosition = new Vector2(0, 900);
            InfoPosition = new Vector2(250, 700);
        }

        public void Update(GameTime gameTime)
        {
            Time += (float) gameTime.ElapsedGameTime.TotalSeconds;
        }

        /// <summary>
        ///     Draws out score, time and enemies-killed text.
        ///     At the start of the game also draws out instructions for the player
        /// </summary>
        /// <param name="spriteBatch"></param>
        public void Draw(SpriteBatch spriteBatch)
        {
            spriteBatch.DrawString(_font, "Score: " + (int) Score,
                ScorePosition, Color.Yellow, 0, Vector2.Zero,
                1.0f, SpriteEffects.None, 0.5f);

            spriteBatch.DrawString(_font, "Time: " + (int) Time,
                TimePosition, Color.FloralWhite, 0, Vector2.Zero,
                1.0f, SpriteEffects.None, 0.5f);

            spriteBatch.DrawString(_font, "Enemies Killed: " + (int) EnemiesKilled,
                EnemiesKilledPosition, Color.AliceBlue, 0, Vector2.Zero,
                1.0f, SpriteEffects.None, 0.5f);

            if (Time <= 4)
            {
                spriteBatch.DrawString(_font, "Control character with WASD, shoot by holding down SPACE",
                    ControlInfoPosition, Color.ForestGreen, 0, Vector2.Zero,
                    1.0f, SpriteEffects.None, 0.5f);
            }
            if (Time >= 2 && Time <= 6)
            {
                spriteBatch.DrawString(_font, "Try to kill as many enemies as you can while avoiding bullets!",
                    InfoPosition, Color.PaleVioletRed, 0, Vector2.Zero,
                    1.0f, SpriteEffects.None, 0.5f);
            }
        }
    }
}