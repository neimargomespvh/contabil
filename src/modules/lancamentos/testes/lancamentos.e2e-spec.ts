import { Test, INestApplication } from '@nestjs/testing';
import * as request from 'supertest';
import { AppModule } from '../../../app.module';
describe('Lancamentos (e2e)', () => {
  let app: INestApplication;
  beforeAll(async () => {
    const m = await Test.createTestingModule({ imports: [AppModule] }).compile();
    app = m.createNestApplication(); await app.init();
  });
  afterAll(async () => app.close());
  it('401 sem token', () => request(app.getHttpServer()).get('/lancamentos?empresaId=e1').expect(401));
});
