/**
 * scripts/handle_comment.js
 * - Číta udalosť (issue alebo issue_comment) cez GITHUB_EVENT_PATH
 * - Ak komentár začína "/gpt", alebo ak je to nové issue s textom, pošle prompt do OpenAI
 * - Odpovie komentárom na issue s obsahom z OpenAI
 *
 * Poznámka: script používa fetch (Node 18+ má built-in fetch).
 */

const fs = require('fs');

const OPENAI_KEY = process.env.OPENAI_API_KEY;
const GITHUB_TOKEN = process.env.GITHUB_TOKEN;
const GITHUB_EVENT_PATH = process.env.GITHUB_EVENT_PATH;
const GITHUB_REPOSITORY = process.env.GITHUB_REPOSITORY;

if (!OPENAI_KEY) {
  console.error('OPENAI_API_KEY missing');
  process.exit(1);
}
if (!GITHUB_TOKEN) {
  console.error('GITHUB_TOKEN missing');
  process.exit(1);
}
if (!GITHUB_EVENT_PATH || !fs.existsSync(GITHUB_EVENT_PATH)) {
  console.error('GITHUB_EVENT_PATH missing or invalid:', GITHUB_EVENT_PATH);
  process.exit(1);
}

async function callOpenAI(prompt) {
  const resp = await fetch('https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${OPENAI_KEY}`,
    },
    body: JSON.stringify({
      model: 'gpt-4o-mini',
      messages: [{ role: 'user', content: prompt }],
      temperature: 0.2,
      max_tokens: 1200,
    }),
  });

  if (!resp.ok) {
    const txt = await resp.text();
    throw new Error(`OpenAI API error ${resp.status}: ${txt}`);
  }
  const data = await resp.json();
  return data.choices?.[0]?.message?.content || '';
}

async function githubApi(path, method = 'GET', body = null) {
  const url = `https://api.github.com${path}`;
  const headers = {
    'Authorization': `token ${GITHUB_TOKEN}`,
    'Accept': 'application/vnd.github+json',
    'User-Agent': 'chatgpt-assistant-action',
  };
  const opts = { method, headers };
  if (body) {
    opts.body = JSON.stringify(body);
    headers['Content-Type'] = 'application/json';
  }
  const res = await fetch(url, opts);
  const text = await res.text();
  try { return JSON.parse(text); } catch { return text; }
}

(async () => {
  try {
    const event = JSON.parse(fs.readFileSync(GITHUB_EVENT_PATH, 'utf8'));

    let prompt = '';
    let issueNumber = null;

    if (event.comment && event.issue) {
      const commentBody = event.comment.body || '';
      issueNumber = event.issue.number;
      const match = commentBody.match(/^\/gpt\s+([\s\S]+)/i);
      if (match) {
        prompt = match[1].trim();
      } else {
        console.log('Comment does not start with /gpt — ignoring.');
        return;
      }
    } else if (event.issue) {
      issueNumber = event.issue.number;
      prompt = event.issue.body || '';
      if (!prompt || !prompt.trim()) {
        console.log('Issue body empty — ignoring.');
        return;
      }
    } else {
      console.log('Event not issue or comment — ignoring.');
      return;
    }

    console.log('Using prompt:', prompt.slice(0, 300));

    const aiResponse = await callOpenAI(prompt);
    console.log('OpenAI responded. Length:', aiResponse.length);

    const reply = `### ChatGPT assistant\n\n${aiResponse}\n\n*Automatická odpoveď generovaná modelom.*`;
    const commentPath = `/repos/${GITHUB_REPOSITORY}/issues/${issueNumber}/comments`;
    await githubApi(commentPath, 'POST', { body: reply });

    console.log('Posted comment to issue #' + issueNumber);
  } catch (err) {
    console.error('Error in assistant script:', err);
    process.exit(1);
  }
})();