import { log, BigInt, Bytes, store } from "@graphprotocol/graph-ts";
import {
  BridgeNuke,
  BridgeChangeOwner,
  Impersonate,
  Deimpersonate,
  Authorize,
  Deauthorize
} from "../generated/PersonaMirror/PersonaMirror";
import { Persona, User, Transfer, Authorization, Impersonation } from "../generated/schema";

export function handleChangeOwner(event: BridgeChangeOwner): void {
  log.debug("BridgeChangeOwner detected. Persona ID: {} | From: {} | To: {} | Nonce: {}", [
    event.params.personaId.toString(),
    event.params.from.toHexString(),
    event.params.to.toHexString(),
    event.params.nonce.toString()
  ]);

  let persona = Persona.load(event.params.personaId.toString());
  let from = User.load(event.params.from.toHexString());
  let to = User.load(event.params.to.toHexString());

  const transferId = event.transaction.hash
    .toHexString()
    .concat(":".concat(event.transactionLogIndex.toHexString()));
  let transfer = Transfer.load(transferId);

  if (
    from == null &&
    event.params.from.toHexString() != "0x0000000000000000000000000000000000000000"
  ) {
    from = new User(event.params.from.toHexString());
    from.authorizations = [];
    from.balance = BigInt.fromI32(0);
  } else if (from) {
    if (from.balance > BigInt.fromI32(0)) {
      from.balance.minus(BigInt.fromI32(1));
    }
  }

  if (to == null && event.params.to.toHexString() != "0x0000000000000000000000000000000000000000") {
    to = new User(event.params.to.toHexString());
    to.balance = BigInt.fromI32(1);
  } else if (to) {
    to.balance.plus(BigInt.fromI32(1));
  }

  if (persona == null) {
    persona = new Persona(event.params.personaId.toString());
    persona.owner = event.params.to.toHexString();
  } else {
    persona.owner = event.params.to.toHexString();

    for (let i = 0; i < persona.authorizations.length; i++) {
      const authorizationId = persona.authorizations[i];
      const authorization = Authorization.load(authorizationId)!;
      const user = User.load(authorization.user)!;
      // if user is currently impersonating this persona, remove it
      for (let j = 0; j < user.impersonations.length; j++) {
        const impersonationId = user.impersonations[i];
        const impersonation = Impersonation.load(impersonationId)!;
        if (impersonation.persona == persona.id) {
          store.remove("Impersonation", impersonationId)
          break;
        }
      }
      store.remove("Authorization", authorizationId)
    }
  }

  if (transfer == null) {
    transfer = new Transfer(transferId);
    transfer.persona = event.params.personaId.toString();
    transfer.from = event.params.from.toHexString();
    transfer.to = event.params.to.toHexString();
    transfer.timestamp = event.block.timestamp;
    transfer.block = event.block.number;
    transfer.transactionHash = event.transaction.hash.toHexString();
  }
  if (from) {
    from.save();
  }
  if (to) {
    to.save();
  }
  persona.save();
  transfer.save();
}

export function handleNuke(event: BridgeNuke): void {
  log.debug("BridgeNuke detected. Persona ID: {} | Nonce: {}", [
    event.params.personaId.toString(),
    event.params.nonce.toString()
  ]);

  let persona = Persona.load(event.params.personaId.toString())!;

  for (let i = 0; i < persona.authorizations.length; i++) {
    const authorizationId = persona.authorizations[i];
    const authorization = Authorization.load(authorizationId)!;
    const user = User.load(authorization.user)!;

    for (let j = 0; j < user.impersonations.length; j++) {
      const impersonationId = user.impersonations[i];
      const impersonation = Impersonation.load(impersonationId)!;
      if (impersonation.persona == persona.id) {
        store.remove("Impersonation", impersonationId)
        break;
      }
    }
    store.remove("Authorization", authorizationId)
  }

  persona.save();
}

function generateImpersonationId(personaId: string, user: string, consumer: string) : string {
  return personaId.concat(":".concat(user.concat(":".concat(consumer))))
}

export function handleImpersonate(event: Impersonate): void {
  log.debug("Impersonate detected. Persona ID: {} | User: {} | Consumer: {}", [
    event.params.personaId.toString(),
    event.params.user.toHexString(),
    event.params.consumer.toHexString()
  ]);

  let impersonationId = generateImpersonationId(event.params.personaId.toString(), event.params.user.toHexString(), event.params.consumer.toHexString());
  let impersonation = Impersonation.load(impersonationId);

  if (impersonation == null) {
    impersonation = new Impersonation(impersonationId);
    impersonation.persona = event.params.personaId.toString();
    impersonation.user = event.params.user.toHexString();
    impersonation.consumer = event.params.consumer.toHexString();
  }

  impersonation.save();
}

export function handleDeimpersonate(event: Deimpersonate): void {
  log.debug("Impersonate detected. Persona ID: {} | User: {} | Consumer: {}", [
    event.params.personaId.toString(),
    event.params.user.toHexString(),
    event.params.consumer.toHexString()
  ]);

  let impersonationId = generateImpersonationId(event.params.personaId.toString(), event.params.user.toHexString(), event.params.consumer.toHexString());
  let impersonation = Impersonation.load(impersonationId);
  if(impersonation) {
    store.remove("Impersonation", impersonationId)
  } else {
    log.warning("A deimpersonate on an unexisting Impersonation entity has been triggered: {}", [impersonationId])
  }
}

export function handleAuthorize(event: Authorize): void {
  log.debug("Authorize detected. Persona ID: {} | User: {} | Consumer: {} | fnSignatures: {}", [
    event.params.personaId.toString(),
    event.params.user.toHexString(),
    event.params.consumer.toHexString(),
    event.params.fnSignatures.toString()
  ]);

  let user = User.load(event.params.user.toHexString())!;
  let persona = Persona.load(event.params.personaId.toString())!;

  let authorizationId = event.transaction.hash
    .toHexString()
    .concat(":".concat(event.transactionLogIndex.toHexString()));
  let authorization = Authorization.load(authorizationId);

  if (authorization == null) {
    authorization = new Authorization(authorizationId);
    authorization.persona = event.params.personaId.toString();
    authorization.user = event.params.user.toHexString();
    authorization.consumer = event.params.consumer.toHexString();
    authorization.fnSignatures = event.params.fnSignatures.map<string>((x: Bytes) => x.toHexString());
  }

  if (user.authorizations == null) {
    user.authorizations = [authorizationId];
  } else {
    user.authorizations.push(authorizationId);
  }

  if (persona.authorizations == null) {
    persona.authorizations = [authorizationId];
  } else {
    persona.authorizations.push(authorizationId);
  }

  user.save();
  persona.save();
}

export function handleDeauthorize(event: Deauthorize): void {
  log.debug("Deauthorize detected. Persona ID: {} | User: {} | Consumer: {}", [
    event.params.personaId.toString(),
    event.params.user.toHexString(),
    event.params.consumer.toHexString()
  ]);

  let user = User.load(event.params.user.toHexString())!;
  let persona = Persona.load(event.params.personaId.toString())!;

  for (let i = 0; i < persona.authorizations.length; i++) {
    let authorization = Authorization.load(persona.authorizations[i])!;

    if (
      authorization.user == event.params.user.toHexString() &&
      authorization.consumer == event.params.consumer.toHexString()
    ) {
      persona.authorizations.splice(i, 1);
      break;
    }
  }

  for (let i = 0; i < user.impersonations.length; i++) {
    let impersonation = Impersonation.load(user.impersonations[i])!;

    if (
      impersonation.user == event.params.user.toHexString() &&
      impersonation.consumer == event.params.consumer.toHexString()
    ) {
      user.impersonations.splice(i, 1);
      break;
    }
  }

  for (let i = 0; i < persona.impersonations.length; i++) {
    let impersonation = Impersonation.load(persona.impersonations[i])!;

    if (
      impersonation.user == event.params.user.toHexString() &&
      impersonation.consumer == event.params.consumer.toHexString()
    ) {
      persona.impersonations.splice(i, 1);
      break;
    }
  }

  user.save();
  persona.save();
}
