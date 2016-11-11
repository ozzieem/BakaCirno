using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Content;
using Microsoft.Xna.Framework.Graphics;

namespace GameProjectOOP
{
    internal class HighScoreText
    {
        private SpriteFont _font;
        public Vector2 ScorePosition, TimePosition, EnemiesKilledPosition;
        public float Time, EnemiesKilled, Score;

        public HighScoreText(TextOverlay gamePlay)
        {
            Score = gamePlay.Score;
            Time = gamePlay.Time;
            EnemiesKilled = gamePlay.EnemiesKilled;
        }

        public void Load(ContentManager content)
        {
            _font = content.Load<SpriteFont>("assets/fonts/Font");

            ScorePosition = new Vector2(310, 380);
            EnemiesKilledPosition = new Vector2(360, 460);
            TimePosition = new Vector2(345, 542);
        }

        public void Draw(SpriteBatch spriteBatch)
        {
            spriteBatch.DrawString(_font, " " + (int) Score,
                ScorePosition, Color.DarkBlue, 0, Vector2.Zero,
                1.5f, SpriteEffects.None, 0.5f);

            spriteBatch.DrawString(_font, " " + (int) EnemiesKilled,
                EnemiesKilledPosition, Color.DarkBlue, 0, Vector2.Zero,
                1.5f, SpriteEffects.None, 0.5f);

            spriteBatch.DrawString(_font, " " + (int) Time + "s",
                TimePosition, Color.DarkBlue, 0, Vector2.Zero,
                1.5f, SpriteEffects.None, 0.5f);
        }
    }
}