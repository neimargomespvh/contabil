import { Injectable, Logger } from '@nestjs/common';
import PDFDocument from 'pdfkit';

export interface DadosGuia {
  tipo: 'DAS' | 'DARF' | 'GPS' | 'ISS';
  numeroDocumento?: string;
  razaoSocial: string;
  cnpj: string;
  periodoApuracao: string;
  vencimento: string;
  valor: number;
  codigoReceita?: string;
  descricao?: string;
  detalhes?: Record<string, string | number>;
}

@Injectable()
export class GuiaGenerator {
  private readonly logger = new Logger(GuiaGenerator.name);

  /**
   * Gera o PDF de uma guia. Retorna o Buffer.
   */
  async gerar(dados: DadosGuia): Promise<Buffer> {
    return new Promise((resolve, reject) => {
      try {
        const doc = new PDFDocument({ size: 'A4', margin: 40 });
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

  private renderizar(doc: PDFKit.PDFDocument, dados: DadosGuia) {
    const largura = doc.page.width - 80;

    // Cabeçalho
    doc.rect(40, 40, largura, 50).fillAndStroke('#003366', '#003366');
    doc.fillColor('#FFFFFF').fontSize(18).text('DOCUMENTO DE ARRECADAÇÃO', 40, 55, {
      width: largura,
      align: 'center',
    });

    // Tipo
    doc.moveDown(3);
    doc.fillColor('#000000').fontSize(12);

    let y = 110;

    // Bloco 1 — Tipo e Identificação
    this.linha(doc, y, 'Tipo de Guia:', dados.tipo);
    y += 20;
    if (dados.numeroDocumento) {
      this.linha(doc, y, 'Nº do Documento:', dados.numeroDocumento);
      y += 20;
    }
    if (dados.codigoReceita) {
      this.linha(doc, y, 'Código de Receita:', dados.codigoReceita);
      y += 20;
    }

    y += 10;
    doc.moveTo(40, y).lineTo(40 + largura, y).stroke('#CCCCCC');
    y += 15;

    // Bloco 2 — Contribuinte
    doc.fontSize(14).fillColor('#003366').text('CONTRIBUINTE', 40, y);
    y += 25;

    doc.fontSize(11).fillColor('#000000');
    this.linha(doc, y, 'Razão Social:', dados.razaoSocial);
    y += 20;
    this.linha(doc, y, 'CNPJ:', this.formatarCnpj(dados.cnpj));
    y += 30;

    // Bloco 3 — Período / Valores
    doc.fontSize(14).fillColor('#003366').text('PERÍODO E VALORES', 40, y);
    y += 25;

    doc.fontSize(11).fillColor('#000000');
    this.linha(doc, y, 'Período de Apuração:', dados.periodoApuracao);
    y += 20;
    this.linha(doc, y, 'Data de Vencimento:', dados.vencimento);
    y += 20;

    // Valor em destaque
    y += 10;
    doc.rect(40, y, largura, 40).fillAndStroke('#F0F0F0', '#003366');
    doc.fillColor('#003366').fontSize(14).text('VALOR TOTAL A PAGAR:', 55, y + 12);
    doc.fontSize(18).text(this.formatarMoeda(dados.valor), 40, y + 10, {
      width: largura - 20,
      align: 'right',
    });
    y += 55;

    // Detalhes
    if (dados.detalhes && Object.keys(dados.detalhes).length > 0) {
      doc.fontSize(14).fillColor('#003366').text('DETALHAMENTO', 40, y);
      y += 25;

      doc.fontSize(10).fillColor('#000000');
      for (const [chave, valor] of Object.entries(dados.detalhes)) {
        this.linha(doc, y, `${chave}:`, String(valor));
        y += 18;
      }
    }

    // Descrição livre
    if (dados.descricao) {
      y += 15;
      doc.fontSize(10).fillColor('#666666').text(dados.descricao, 40, y, { width: largura });
    }

    // Rodapé
    const rodapeY = doc.page.height - 60;
    doc.fontSize(8).fillColor('#999999').text(
      `Documento gerado em ${new Date().toLocaleString('pt-BR')} — Sistema Contábil`,
      40,
      rodapeY,
      { width: largura, align: 'center' },
    );
  }

  private linha(doc: PDFKit.PDFDocument, y: number, label: string, valor: string) {
    doc.font('Helvetica-Bold').text(label, 45, y, { continued: false, width: 180 });
    doc.font('Helvetica').text(valor, 230, y, { width: doc.page.width - 270 });
  }

  private formatarMoeda(valor: number): string {
    return valor.toLocaleString('pt-BR', { style: 'currency', currency: 'BRL' });
  }

  private formatarCnpj(cnpj: string): string {
    const limpo = cnpj.replace(/\D/g, '');
    return limpo.replace(/^(\d{2})(\d{3})(\d{3})(\d{4})(\d{2})$/, '$1.$2.$3/$4-$5');
  }
}
