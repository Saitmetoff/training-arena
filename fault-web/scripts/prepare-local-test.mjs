import {randomBytes} from 'node:crypto';
import {writeFile,access} from 'node:fs/promises';
try {await access('.env.local');console.log('Existing local configuration retained.');} catch {
 await writeFile('.env.local',`FAULT_SITE_URL=http://127.0.0.1:3000\nFAULT_ENVIRONMENT=development\nFAULT_LOCAL_TEST_MODE=true\nFAULT_ENCRYPTION_KEY=${randomBytes(32).toString('hex')}\nFAULT_RATE_LIMIT_SECRET=${randomBytes(32).toString('hex')}\nFAULT_DISPATCH_SECRET=${randomBytes(32).toString('hex')}\n`);
 console.log('Ignored loopback-only simulated configuration prepared; no email is sent.');
}
