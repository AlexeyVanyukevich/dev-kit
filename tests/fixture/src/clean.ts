export interface Booking {
  id: string
  note?: string
}

export function firstId(bookings: readonly Booking[]): string | undefined {
  // Correct under noUncheckedIndexedAccess: the index may be out of range, and the type says so.
  return bookings[0]?.id
}

export function withNote(booking: Booking, note: string | undefined): Booking {
  // Correct under exactOptionalPropertyTypes: the key is omitted rather than set to undefined.
  return note === undefined ? { id: booking.id } : { id: booking.id, note }
}
