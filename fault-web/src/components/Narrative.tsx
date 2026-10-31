import Image from 'next/image';
import type { ReactNode } from 'react';

export type NarrativeProps = {
  signup?: ReactNode;
  finalSignup?: ReactNode;
  share?: ReactNode;
  demo?: ReactNode;
};

export default function Narrative({ signup, finalSignup, share, demo }: NarrativeProps) {
  return (
    <>
      <a className="skip" href="#main">Skip to content</a>

      <header className="site-header">
        <div className="page header-inner">
          <span className="wordmark">
            <Image src="/fault-wordmark.svg" alt="Fault" width={144} height={33} priority />
          </span>
          <nav className="masthead" aria-label="Primary">
            <a href="#join">Join the waitlist</a>
          </nav>
        </div>
      </header>

      <main id="main" tabIndex={-1}>
        <section className="hero" aria-labelledby="hero-title">
          <div className="page hero-grid">
            <div className="hero-copy">
              <p className="eyebrow">FAULT · IN DEVELOPMENT</p>
              <h1 className="headline" id="hero-title" aria-label="Give your next set a reason.">
                <span className="hl">Give your</span>
                <span className="hl">next set</span>
                <span className="hl">a reason.</span>
              </h1>
              <p className="subline">
                Fault is being built for solo push-up practice: enter your own rep count, save the set on your phone, and compare it with your previous sets. Android first.
              </p>
              <div className="signup-slot" id="join">
                {signup}
              </div>
            </div>

            <div className="hero-media">
              {demo || <div className="media-editorial">
                <div className="media-chrome">
                  <span>SOLO · DEVELOPMENT BUILD</span>
                  <span>MISSING MEDIA</span>
                </div>
                <div className="media-body">
                  <p className="media-title">Solo demonstration</p>
                  <p className="media-note">Footage not yet recorded</p>
                  <p className="media-flow">
                    Reserved for a real solo set: complete your push-ups, enter your count, save and review your set.
                  </p>
                </div>
              </div>}
              {!demo && <p className="media-caption">
                Development build · Solo push-ups · Reps entered by the athlete.
              </p>}
            </div>
          </div>
        </section>

        <section className="next" aria-labelledby="next-title">
          <div className="page">
            <div className="next-head">
              <h2 className="next-heading" id="next-title">Do the set. Keep the record.</h2>
            </div>
            <div className="process-editorial">
              <ol className="process-list">
                <li><span className="step">01</span> Complete your push-ups.</li>
                <li><span className="step">02</span> Enter your count.</li>
                <li><span className="step">03</span> Save and review your set.</li>
              </ol>
            </div>
            <div className="benefits-head">
              <h2 className="next-heading" id="benefits-title">A reason to come back.</h2>
            </div>
            <ul className="benefits" aria-labelledby="benefits-title">
              <li>
                <h3>Your effort, recorded.</h3>
                <p>Complete a push-up set and enter the reps yourself. Your result is clearly marked self-reported.</p>
              </li>
              <li>
                <h3>A record to compare.</h3>
                <p>Review your last seven days and your personal best within saved history. Results stay on your phone.</p>
              </li>
              <li>
                <h3>Start on your own terms.</h3>
                <p>Solo practice works without an app account. Your sets are personal practice, separate from competitive ratings.</p>
              </li>
            </ul>
          </div>
        </section>

        <section className="faq" aria-labelledby="faq-title">
          <div className="page">
            <h2 className="next-heading" id="faq-title">Frequently asked questions</h2>
            <div className="faq-list">
              <details>
                <summary>What can I do in Fault?</summary>
                <p>The first experience centers on solo push-ups: complete a set, enter your own rep count, and save it on your phone. You can review recent sets and your personal best within saved history. Fault is still in development.</p>
              </details>
              <details>
                <summary>Does the camera count my reps?</summary>
                <p>Camera counting is being tested and is not available in the current beta scope. For now, you count your push-ups and enter the number yourself. We will explain supported setups when device testing is complete.</p>
              </details>
              <details>
                <summary>Can I battle a friend?</summary>
                <p>Friend battles for push-ups and squats are in development. They need camera counting and further device and online testing before we can offer completed battles. We are not announcing battle availability yet.</p>
              </details>
              <details>
                <summary>Do I need an account?</summary>
                <p>Solo practice is designed to work signed out. Battles require sign-in. Joining the website waitlist confirms your email; it does not create an app account.</p>
              </details>
              <details>
                <summary>Where is my set history saved?</summary>
                <p>Saved sets stay on your phone, so your history needs the same phone. Your sets are not stored in a cloud account.</p>
              </details>
              <details>
                <summary>Which phones will be supported?</summary>
                <p>We are preparing Fault for Android first. The tested device list will be shared before access opens. We have not announced an iPhone release or browser gameplay.</p>
              </details>
              <details>
                <summary>Do I need equipment?</summary>
                <p>You record your bodyweight push-up sets on an Android phone. We will share setup guidance if camera counting becomes available.</p>
              </details>
              <details>
                <summary>When will it launch?</summary>
                <p>There is no confirmed public launch date. Join and confirm your email for updates. Our audience goal is 30,000 confirmed subscribers; the app also needs to pass release checks before public launch. Signing up does not unlock access.</p>
              </details>
              <details>
                <summary>Will it be free?</summary>
                <p>The first beta is planned to be free while we validate the experience. Public launch pricing has not been finalized.</p>
              </details>
              <details>
                <summary>What happens to camera footage?</summary>
                <p>The camera implementation processes frames on the phone instead of uploading them for counting. Camera counting remains under test. Your waitlist email is handled separately, under the website privacy policy.</p>
              </details>
            </div>
          </div>
        </section>

        <section className="final" aria-labelledby="final-title">
          <div className="page">
            <h2 className="next-heading" id="final-title">Make room for your next set.</h2>
            <p className="subline">Confirm your email. Get Fault updates when there is something to share.</p>
            <div className="signup-slot">
              {finalSignup}
            </div>
            {share != null ? <div className="share-slot">{share}</div> : null}
          </div>
        </section>
      </main>

      <footer className="site-footer">
        <div className="page">
          <p className="closing">Fault is in development.</p>
          <nav className="footer-links" aria-label="Support">
            <a href="/privacy">Privacy</a>
            <a href="/support">Support</a>
          </nav>
        </div>
      </footer>
    </>
  );
}
