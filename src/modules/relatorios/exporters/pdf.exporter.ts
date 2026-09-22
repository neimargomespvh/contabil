import { Injectable } from '@nestjs/common';
import PDFDocument from 'pdfkit';

export interface DadosRelatorio {
  titulo: string;
  empresaNome: string;
  empresaCnpj: string;
  periodo: string;
  colunas: string[];
  linhas: Array<string[]>;
  totais?: Array<string[]>;
  larguras?: number[];
}

@Injectable()
export class PdfExporter {
  async exportar(dados: DadosRelatorio): Promise<Buffer> {
    return new Promise((resolve, reject) => {
      try {
        const doc = new PDFDocument({
          size: 'A4',
          margin: 30,
          layout: dados.colunas.length > 5 ? 'landscape' : 'portrait',
        });
        const chunks: Buffer[] = [];
        doc.on('data', (c) => chunks.push(c));
        doc.on('end', () => resolve(Buffer.concat(chunks)));
        doc.on('error', reject);

        this.renderizar(doc, dados);
        doc.end();
      } catch (err) {
        reject(err);
      }
    });
  }

  private renderizar(doc: PDFKit.PDFDocument, dados: DadosRelatorio) {
    const larguraPag = doc.page.width - 60;

    // Cabeçalho
    doc.font('Helvetica-Bold').fontSize(14).fillColor('#003366')
      .text(dados.empresaNome, 30, 30, { width: larguraPag, align: 'center' });
    doc.font('Helvetica').fontSize(9).fillColor('#333333')
      .text(`CNPJ: ${this.formatarCnpj(dados.empresaCnpj)}`, { width: larguraPag, align: 'center' });
    doc.font('Helvetica-Bold').fontSize(12).fillColor('#003366')
      .text(dados.titulo, { width: larguraPag, align: 'center' });
    doc.font('Helvetica').fontSize(9)
      .text(`Período: ${dados.periodo}`, { width: larguraPag, align: 'center' });

    doc.moveDown(1);

    const larguras = dados.larguras ?? this.distribuirLarguras(dados.colunas.length, larguraPag);
    const alturaLinha = 18;
    let y = doc.y;

    // Cabeçalho de colunas
    doc.rect(30, y, larguraPag, alturaLinha).fill('#003366');
    doc.fillColor('#FFFFFF').fontSize(8).font('Helvetica-Bold');
    let x = 30;
    for (let i = 0; i < dados.colunas.length; i++) {
      doc.text(dados.colunas[i], x + 3, y + 5, { width: larguras[i] - 6, align: i === 0 ? 'left' : 'right' });
      x += larguras[i];
    }
    y += alturaLinha;

    // Linhas
    doc.font('Helvetica').fontSize(8).fillColor('#000000');
    let zebra = false;
    for (const linha of dados.linhas) {
      if (y + alturaLinha > doc.page.height - 50) {
        doc.addPage();
        y = 30;
      }
      if (zebra) {
        doc.rect(30, y, larguraPag, alturaLinha).fill('#F5F5F5');
      }
      zebra = !zebra;

      doc.fillColor('#000000');
      x = 30;
      for (let i = 0; i < linha.length; i++) {
        doc.text(String(linha[i] ?? ''), x + 3, y + 5, {
          width: larguras[i] - 6,
          align: i === 0 ? 'left' : 'right',
          ellipsis: true,
        });
        x += larguras[i];
      }
      y += alturaLinha;
    }

    // Totais
    if (dados.totais && dados.totais.length > 0) {
      y += 4;
      doc.rect(30, y, larguraPag, alturaLinha).fill('#DDDDDD');
      doc.font('Helvetica-Bold').fillColor('#000000');
      for (const totLinha of dados.totais) {
        x = 30;
        for (let i = 0; i < totLinha.length; i++) {
          doc.text(String(totLinha[i] ?? ''), x + 3, y + 5, {
            width: larguras[i] - 6,
            align: i === 0 ? 'left' : 'right',
          });
          x += larguras[i];
        }
        y += alturaLinha;
      }
    }

    // Rodapé
    const rodapeY = doc.page.height - 30;
    doc.font('Helvetica').fontSize(7).fillColor('#999999').text(
      `Gerado em ${new Date().toLocaleString('pt-BR')} — Sistema Contábil`,
      30,
      rodapeY,
      { width: larguraPag, align: 'center' },
    );
  }

  private distribuirLarguras(n: number, total: number): number[] {
    if (n <= 1) return [total];
    const primeira = total * 0.35;
    const restante = (total - primeira) / (n - 1);
    return [primeira, ...Array(n - 1).fill(restante)];
  }

  private formatarCnpj(cnpj: string): string {
    const limpo = cnpj.replace(/\D/g, '');
    return limpo.replace(/^(\d{2})(\d{3})(\d{3})(\d{4})(\d{2})$/, '$1.$2.$3/$4-$5');
  }
}
