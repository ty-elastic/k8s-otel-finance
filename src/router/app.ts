/*app.ts*/
import express, { Express } from 'express';
import type { Request, Response } from 'express';

import { createProxyMiddleware } from 'http-proxy-middleware';

import { Logger } from "tslog";
const logger = new Logger({ name: "router", type: "json" });

const PORT: number = parseInt(process.env.PORT || '9000');
const app: Express = express();

function getRandomBoolean() {
  return Math.random() < 0.5;
}

function customRouter(req: any) {
  var host = "";
  if (req.query.service != null) {
    host = `http://${req.query.service}:9003`;
  }
  else {
    if (req.query.canary === 'true')
      host = `http://${process.env.RECORDER_HOST_CANARY}:9003`;
    else {
      if (process.env.RECORDER_HOST_2 == null)
        host = `http://${process.env.RECORDER_HOST_1}:9003`;
      else if (getRandomBoolean())
        host = `http://${process.env.RECORDER_HOST_1}:9003`;
      else
        host = `http://${process.env.RECORDER_HOST_2}:9003`;
    }
  }

  logger.info({ host: host }, `routing request`);
  return host;
};

const proxyMiddleware = createProxyMiddleware<Request, Response>({
  router: customRouter,
  changeOrigin: false
})

app.use('/', proxyMiddleware);

app.get('/health', (req, res) => {
  res.send("KERNEL OK")
});

app.listen(PORT, () => {
  logger.info(`Listening for requests on http://localhost:${PORT}`);
});
