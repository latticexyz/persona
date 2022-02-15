import { log, BigInt } from '@graphprotocol/graph-ts';
import { Persona, Transfer as TransferEvent } from '../generated/Persona/Persona';
import { Persona as PersonaEntity, Owner, Transfer } from '../generated/schema';

export function handleTransfer(event: TransferEvent): void {
  log.debug('Transfer detected. From: {} | To: {} | TokenID: {}', [
    event.params.from.toHexString(),
    event.params.to.toHexString(),
    event.params.id.toHexString(),
  ]);

  let previousOwner = Owner.load(event.params.from.toHexString());
  let newOwner = Owner.load(event.params.to.toHexString());
  let persona = PersonaEntity.load(event.params.id.toHexString());
  let transferId = event.transaction.hash
    .toHexString()
    .concat(':'.concat(event.transactionLogIndex.toHexString()));
  let transfer = Transfer.load(transferId);
  let instance = Persona.bind(event.address);

  if (previousOwner == null) {
    previousOwner = new Owner(event.params.from.toHexString());

    previousOwner.balance = BigInt.fromI32(0);
  } else {
    let prevBalance = previousOwner.balance;
    if (prevBalance > BigInt.fromI32(0)) {
      previousOwner.balance = prevBalance.minus(BigInt.fromI32(1));
    }
  }

  if (newOwner == null) {
    newOwner = new Owner(event.params.to.toHexString());
    newOwner.balance = BigInt.fromI32(1);
  } else {
    let prevBalance = newOwner.balance;
    newOwner.balance = prevBalance.plus(BigInt.fromI32(1));
  }

  if (persona == null) {
    persona = new PersonaEntity(event.params.id.toHexString());
    let uri = instance.try_tokenURI(event.params.id);
    if (!uri.reverted) {
      persona.uri = uri.value;
    }
  }

  persona.owner = event.params.to.toHexString();

  if (transfer == null) {
    transfer = new Transfer(transferId);
    transfer.persona = event.params.id.toHexString();
    transfer.from = event.params.from.toHexString();
    transfer.to = event.params.to.toHexString();
    transfer.timestamp = event.block.timestamp;
    transfer.block = event.block.number;
    transfer.transactionHash = event.transaction.hash.toHexString();
  }

  previousOwner.save();
  newOwner.save();
  persona.save();
  transfer.save();
}
