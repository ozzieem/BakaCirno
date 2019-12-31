using Microsoft.Xna.Framework.Audio;
using Microsoft.Xna.Framework.Content;

namespace BakaCirno
{
    class Sound
    {
        public SoundEffect PlayingSong;
        public SoundEffect ButtonPlaySelect;
        public SoundEffect EnemyDeath, EnemyCircleShoot, EnemyRandomShoot;
        public SoundEffect PlayerShoot, PlayerDeath;

        public void Load(ContentManager content)
        {
            // Previously CirnoThemeSongWAV
            PlayingSong = content.Load<SoundEffect>("assets/sound/CirnoThemeSongWMA");
            ButtonPlaySelect = content.Load<SoundEffect>("assets/sound/ButtonPlaySelectSFX");

            PlayerShoot = content.Load<SoundEffect>("assets/sound/PlayershotSFX");
            PlayerDeath = content.Load<SoundEffect>("assets/sound/DeathSFX");

            EnemyCircleShoot = content.Load<SoundEffect>("assets/sound/EnemyShootSFX1");
            EnemyRandomShoot = content.Load<SoundEffect>("assets/sound/EnemyShootSFX2");
            EnemyDeath = content.Load<SoundEffect>("assets/sound/enemyDeathSFX");
        }
    }
}