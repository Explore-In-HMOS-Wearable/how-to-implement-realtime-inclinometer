export enum MeasurementStatus {
  MEASURING = 'measuring',
  SENSOR_UNAVAILABLE = 'sensor_unavailable',
  ERROR = 'error',
  STOPPED = 'stopped'
}

export interface InclinometerReading {
  pitch: number; // Degrees calculated from the device X acceleration axis.
  roll: number; // Degrees calculated from the device Y acceleration axis.
  status: MeasurementStatus;
}
