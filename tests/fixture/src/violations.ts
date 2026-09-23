export interface Booking {
  id: string
  note?: string
}

// noUncheckedIndexedAccess: bookings[0] is `Booking | undefined`, not `Booking`. TS2322.
export function firstBooking(bookings: readonly Booking[]): Booking {
  return bookings[0]
}

// exactOptionalPropertyTypes: an optional key may be absent, not present-and-undefined. TS2375.
export const withoutNote: Booking = { id: 'b1', note: undefined }
