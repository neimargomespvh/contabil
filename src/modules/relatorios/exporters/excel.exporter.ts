import { Injectable } from '@nestjs/common';
import * as ExcelJS from 'exceljs';
import { DadosRelatorio } from './pdf.exporter';

@Injectable()
export class ExcelExporter {
  async exportar(dados: DadosRelatorio): Promise<Buffer> {
    const wb = new ExcelJS.Workbook();
    wb.creator = 'Sistema Contábil';
    wb.created = new Date();

    const ws = wb.addWorksheet(dados.titulo.slice(0, 30));

    // Cabeçalho
    ws.mergeCells('A1', `${this.letra(dados.colunas.length)}1`);
    ws.getCell('A1').value = dados.empresaNome;
    ws.getCell('A1').font = { bold: true, size: 14, color: { argb: 'FF003366' } };
    ws.getCell('A1').alignment = { horizontal: 'center' };

    ws.mergeCells('A2', `${this.letra(dados.colunas.length)}2`);
    ws.getCell('A2').value = `CNPJ: ${dados.empresaCnpj}`;
    ws.getCell('A2').alignment = { horizontal: 'center' };
    ws.getCell('A2').font = { size: 9 };

    ws.mergeCells('A3', `${this.letra(dados.colunas.length)}3`);
    ws.getCell('A3').value = dados.titulo;
    ws.getCell('A3').font = { bold: true, size: 12 };
    ws.getCell('A3').alignment = { horizontal: 'center' };

    ws.mergeCells('A4', `${this.letra(dados.colunas.length)}4`);
    ws.getCell('A4').value = `Período: ${dados.periodo}`;
    ws.getCell('A4').alignment = { horizontal: 'center' };
    ws.getCell('A4').font = { size: 9 };

    // Cabeçalho de colunas (linha 6)
    const headerRow = ws.getRow(6);
    dados.colunas.forEach((c, i) => {
      const cell = headerRow.getCell(i + 1);
      cell.value = c;
      cell.font = { bold: true, color: { argb: 'FFFFFFFF' } };
      cell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FF003366' } };
      cell.alignment = { horizontal: i === 0 ? 'left' : 'right', vertical: 'middle' };
      cell.border = {
        top: { style: 'thin' }, bottom: { style: 'thin' },
        left: { style: 'thin' }, right: { style: 'thin' },
      };
    });
    headerRow.height = 20;

    // Linhas
    let linhaAtual = 7;
    for (const linha of dados.linhas) {
      const row = ws.getRow(linhaAtual);
      linha.forEach((v, i) => {
        const cell = row.getCell(i + 1);
        // Tentar número
        const num = this.parseNumero(v);
        cell.value = num !== null ? num : v;
        if (num !== null) {
          cell.numFmt = '#,##0.00';
        }
        cell.alignment = { horizontal: i === 0 ? 'left' : 'right' };
      });
      linhaAtual++;
    }

    // Totais
    if (dados.totais) {
      for (const tot of dados.totais) {
        const row = ws.getRow(linhaAtual);
        tot.forEach((v, i) => {
          const cell = row.getCell(i + 1);
          const num = this.parseNumero(v);
          cell.value = num !== null ? num : v;
          if (num !== null) cell.numFmt = '#,##0.00';
          cell.font = { bold: true };
          cell.alignment = { horizontal: i === 0 ? 'left' : 'right' };
        });
        linhaAtual++;
      }
    }

    // Ajustar larguras
    dados.colunas.forEach((_, i) => {
      const col = ws.getColumn(i + 1);
      col.width = i === 0 ? 40 : 18;
    });

    const buffer = await wb.xlsx.writeBuffer();
    return Buffer.from(buffer);
  }

  private letra(n: number): string {
    let s = '';
    while (n > 0) {
      const resto = (n - 1) % 26;
      s = String.fromCharCode(65 + resto) + s;
      n = Math.floor((n - 1) / 26);
    }
    return s || 'A';
  }

  private parseNumero(v: any): number | null {
    if (typeof v === 'number') return v;
    if (typeof v !== 'string') return null;
    const limpo = v.replace(/[R$\s.]/g, '').replace(',', '.');
    if (!/^-?\d+(\.\d+)?$/.test(limpo)) return null;
    const n = parseFloat(limpo);
    return isNaN(n) ? null : n;
  }
}
