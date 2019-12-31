using System.Collections.Generic;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Content;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;

namespace BakaCirno
{
    /// <summary>
    ///     The player class for the user
    /// </summary>
    internal class Player
    {
        public Player()
        {
            position = new Vector2(400, 700); // Start-position
            bullets = new List<Bullet>();
            bulletDelay = maxBulletDelay;
            isColliding = false;
            isDead = false;
            soundPlayed = false;
            stopMovement = true;
        }

        public void LoadPlayer(ContentManager content)
        {
            rightAnim = content.Load<Texture2D>("assets/textures/rightcirno");
            idleAnim = content.Load<Texture2D>("assets/textures/idlecirno");
            leftAnim = content.Load<Texture2D>("assets/textures/leftcirno");

            explosionAnim = content.Load<Texture2D>("assets/textures/blueexplosion");
            bulletTexture = content.Load<Texture2D>("assets/textures/playershot1mini");
            powerShotTexture = content.Load<Texture2D>("assets/textures/playershot1");

            // Temporary textures, but works fine
            bulletBBoxTexture = content.Load<Texture2D>("assets/textures/Redshot1");
            pointBBoxTexture = content.Load<Texture2D>("assets/textures/pointBullethalfsize");

            currentAnim = idleAnim;
            sound.Load(content);
        }

        public void Update(GameTime gameTime)
        {
            if (!stopMovement)
            {
                KeyInput();
            }
            UpdateBullets(gameTime);
            BoundaryCheck();
            if (!isColliding)
            {
                Animate(gameTime);
            }
            else
            {
                DeathAnimation(gameTime);

                //Set true after 1500 ms for the explosion-animation to end
                isDead = TrueAfter(1500f, gameTime);
            }

            // Keeps the animation in place
            destRect = new Rectangle((int) position.X, (int) position.Y, 64, 128);

            bulletBoundingBox = new Rectangle((int) position.X, (int) position.Y + 35,
                bulletBBoxTexture.Width - 10, bulletBBoxTexture.Height - 10);

            pointBoundingBox = new Rectangle((int) position.X + 40, (int) position.Y,
                pointBBoxTexture.Width, pointBBoxTexture.Height);
        }

        public void Draw(SpriteBatch spriteBatch)
        {
            spriteBatch.Draw(currentAnim, destRect, playerBody, Color.White);

            foreach (var bullet in bullets)
            {
                bullet.Draw(spriteBatch);
            }
        }

        /// <summary>
        ///     Draws the player-animations
        /// </summary>
        /// <param name="gameTime"></param>
        private void Animate(GameTime gameTime)
        {
            elapsed += (float) gameTime.ElapsedGameTime.TotalMilliseconds;
            var nFrames = 0;
            var frameWidth = 0;

            // Hardcoded because of different sprite size
            if (currentAnim == idleAnim)
            {
                nFrames = 5;
                frameWidth = 68;
            }
            else if (currentAnim == rightAnim)
            {
                nFrames = 5;
                frameWidth = 60;
            }
            else if (currentAnim == leftAnim)
            {
                nFrames = 7;
                frameWidth = 71;
            }

            if (elapsed >= animationDelay)
            {
                if (frames >= nFrames)
                {
                    frames = 0;
                }
                else
                {
                    frames++;
                }
                elapsed = 0;
            }

            // Sets the main frame to the current looping animation
            playerBody = new Rectangle(frameWidth*frames, 0, frameWidth, 128);
        }

        /// <summary>
        ///     Draws the death-animation of the player
        /// </summary>
        /// <param name="gameTime"></param>
        private void DeathAnimation(GameTime gameTime)
        {
            elapsed += (float) gameTime.ElapsedGameTime.TotalMilliseconds;

            stopMovement = true;

            if (!soundPlayed) //Work-around to prevent multiple play in update
            {
                sound.PlayerDeath.Play(0.01f, 0.0f, 0.0f);
                soundPlayed = true;
            }

            var frameWidth = 91;

            currentAnim = explosionAnim;

            if (elapsed >= deathAnimationDelay)
            {
                frames++;
                elapsed = 0;
            }

            // Sets the main frame to the current looping animation
            playerBody = new Rectangle(frameWidth*frames, 0, frameWidth, explosionAnim.Height);
        }

        /// <summary>
        ///     Used to delay the IsDead-value to let the explosion-animation play fully.
        ///     Would not be needed if the Death-animation had its own class, will be fixed.
        /// </summary>
        /// <param name="waitMilliSeconds"></param>
        /// <param name="gameTime"></param>
        /// <returns></returns>
        private bool TrueAfter(float waitMilliSeconds, GameTime gameTime)
        {
            currentMilliSeconds += (float) gameTime.ElapsedGameTime.TotalMilliseconds;
            if (waitMilliSeconds <= currentMilliSeconds)
            {
                return true;
            }
            return false;
        }

        /// <summary>
        ///     Disables the player to move out of the window-screen
        /// </summary>
        private void BoundaryCheck()
        {
            if (position.X <= 0)
            {
                position.X = 0;
            }
            if (position.X >= 920 - playerBody.Width)
            {
                position.X = 920 - playerBody.Width;
            }
            if (position.Y <= 0)
            {
                position.Y = 0;
            }
            if (position.Y >= 950 - playerBody.Height + 40)
            {
                position.Y = 950 - playerBody.Height + 40;
            }
        }

        /// <summary>
        ///     Moves the Bullet-objects upwards
        /// </summary>
        /// <param name="gameTime"></param>
        private void UpdateBullets(GameTime gameTime)
        {
            foreach (var bullet in bullets)
            {
                bullet.boundingBox = new Rectangle((int) bullet.position.X, (int) bullet.position.Y,
                    bullet.texture.Width, bullet.texture.Height);

                bullet.position.Y -= bullet.speed;

                // Bullets keep in range within player y-axis
                difference = position - bullet.position;
                difference.Normalize();
                bullet.position.X += difference.X*(float) gameTime.ElapsedGameTime.TotalMilliseconds*2;
            }
            for (var i = 0; i < bullets.Count; ++i)
            {
                if (!bullets[i].isVisible)
                {
                    bullets.RemoveAt(i);
                    i--;
                }
            }
        }

        /// <summary>
        ///     Shoots if correct key is pressed
        /// </summary>
        private void Shoot()
        {
            currBulletTexture = powerShot ? powerShotTexture : bulletTexture;

            if (bulletDelay >= 0)
            {
                bulletDelay--;
            }

            if (bulletDelay <= 0)
            {
                sound.PlayerShoot.Play(0.005f, 0.8f, 0.0f);

                //Spawns a new bullet at playerposition
                var newBullet = new Bullet(currBulletTexture, position, bulletSpeed);

                bullets.Add(newBullet);
            }

            if (bulletDelay == 0.0)
            {
                bulletDelay = maxBulletDelay;
            }
        }

        /// <summary>
        ///     Checks for key-input
        /// </summary>
        private void KeyInput()
        {
            ks = Keyboard.GetState();

            if (currentAnim == explosionAnim)
                currentAnim = explosionAnim;
            else
                currentAnim = idleAnim;

            if (ks.IsKeyDown(Keys.Right) || ks.IsKeyDown(Keys.D))
            {
                position.X += movementSpeed;
                currentAnim = rightAnim;
            }
            if (ks.IsKeyDown(Keys.Left) || ks.IsKeyDown(Keys.A))
            {
                position.X -= movementSpeed;
                currentAnim = leftAnim;
            }
            if (ks.IsKeyDown(Keys.Up) || ks.IsKeyDown(Keys.W))
            {
                position.Y -= movementSpeed;
                currentAnim = idleAnim;
            }
            if (ks.IsKeyDown(Keys.Down) || ks.IsKeyDown(Keys.S))
            {
                position.Y += movementSpeed;
                currentAnim = idleAnim;
            }
            if (ks.IsKeyDown(Keys.Space) || ks.IsKeyDown(Keys.LeftControl))
            {
                Shoot();
            }

            // PowerShot
            //TODO: In the future, this might be a cooldown type of shot
            if (ks.IsKeyDown(Keys.LeftShift))
            {
                powerShot = true;
            }
            else
            {
                powerShot = false;
            }
        }

        #region Properties

        public Texture2D
            rightAnim,
            leftAnim,
            idleAnim,
            explosionAnim,
            currentAnim;

        private Texture2D
            bulletBBoxTexture,
            pointBBoxTexture,
            currBulletTexture;

        private Texture2D bulletTexture, powerShotTexture;
        public Rectangle bulletBoundingBox, pointBoundingBox;
        public Rectangle destRect, playerBody;
        public Vector2 position;
        private Vector2 difference;
        public List<Bullet> bullets;

        private readonly float maxBulletDelay = 5; // Change Shoot-delay
        private readonly float movementSpeed = 8f; // Change Player-speed
        private float elapsed, bulletDelay;
        public float currentMilliSeconds;
        private const float deathAnimationDelay = 40f;
        public const float animationDelay = 120f;

        public bool isColliding, isDead;
        public bool powerShot;
        public bool soundPlayed, stopMovement;

        private readonly int bulletSpeed = 15;
        private int frames;

        public KeyboardState ks;
        private readonly Sound sound = new Sound();

        #endregion
    }
}