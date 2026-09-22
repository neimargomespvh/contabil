// Necessário para serializar campos BigInt em respostas JSON.
// O Prisma usa BigInt para autoincrement, e o JSON.stringify padrão
// do Node.js não sabe lidar com BigInt.
declare global {
  interface BigInt {
    toJSON(): number | string;
  }
}

BigInt.prototype.toJSON = function () {
  const int = Number(this);
  // Se o número for maior que o safe integer do JS, retorna string
  if (Number.isSafeInteger(int)) return int;
  return this.toString();
};

export {};
