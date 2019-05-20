'use strict';

const record = require('node-record-lpcm16');
const Speaker = require('speaker');
const path = require('path');
const GoogleAssistant = require('google-assistant');
const speakerHelper = require('./speaker-helper');
const http = require('http');
const url = require('url');
const open = require('open');
const fs = require('fs')
const destroyer = require('server-destroy');

const content = fs.readFileSync(path.resolve(__dirname, 'response.html'));

const config = {
  auth: {
    keyFilePath: path.resolve(__dirname, process.argv[2]),
    savedTokensPath: path.resolve(__dirname, 'tokens.json'), // where you want the tokens to be saved
    tokenInput: function(processTokens) {
      const server = http
        .createServer(async (req, res) => {
          try {
            if (req.url.indexOf('/oauth2callback') > -1) {
              // acquire the code from the querystring, and close the web server.
              const qs = new url.URL(req.url, 'http://localhost:3000')
                .searchParams;
              const code = qs.get('code');
              res.end(content);
              processTokens(code);
              server.destroy();
              resolve(true);
            }
          } catch (e) {
            //reject(e);
          }
        })
        .listen(3000, () => {
          // open the browser to the authorize url to start the workflow
          //open(authorizeUrl, {wait: false}).then(cp => cp.unref());
        });
      destroyer(server);
    }
  },
  conversation: {
    audio: {
      sampleRateOut: 24000, // defaults to 24000
    },
    lang: 'en-US', // defaults to en-US, but try other ones, it's fun!
  }
};

const out = (obj) => console.log(JSON.stringify(obj));

const startConversation = (conversation) => {
  out({type: 'ready'});
  let openMicAgain = false;

  // setup the conversation
  conversation
    // send the audio buffer to the speaker
    .on('audio-data', (data) => {
      speakerHelper.update(data);
    })
    // done speaking, close the mic
    .on('end-of-utterance', () => record.stop())
    // just to spit out to the console what was said (as we say it)
    .on('transcription', data => out({type: 'transcription', script: data.transcription, isDone: data.done}))
    // what the assistant said back
    .on('response', text => out({type: 'textResponse', text}))
    // if we've requested a volume level change, get the percentage of the new level
    .on('volume-percent', percent => out({type: 'volumeChange', percent}))
    // the device needs to complete an action
    .on('device-action', action => out({type: 'devAction', action}))
    // once the conversation is ended, see if we need to follow up
    .on('ended', (error, continueConversation) => {
      if (error) out({type: 'error', error});
      else if (continueConversation) openMicAgain = true;
      else out({type: 'complete'});
    })
    // catch any errors
    .on('error', (error) => {
        out({type: 'error', error});
    });

  // pass the mic audio to the assistant
  const mic = record.start({ threshold: 0, recordProgram: 'arecord' });
  mic.on('data', data => conversation.write(data));

  // setup the speaker
  const speaker = new Speaker({
    channels: 1,
    sampleRate: config.conversation.audio.sampleRateOut,
  });
  speakerHelper.init(speaker);
  speaker
    .on('open', () => {
      out({type: 'asstSpeaking', speaking: true});
      speakerHelper.open();
    })
    .on('close', () => {
        out({type: 'asstSpeaking', speaking: false});
      if (openMicAgain) assistant.start(config.conversation);
    });
};

// setup the assistant
const assistant = new GoogleAssistant(config.auth);
assistant
  .on('ready', () => {
    // start a conversation!
    assistant.start(config.conversation);
  })
  .on('started', startConversation)
  .on('error', (error) => {
    out({type: 'error', error})
});