const ALPHA: number = 0.98;
const MAX_DT_SECONDS: number = 0.25;

export class ComplementaryFilter {
  pitch: number = 0; // Radians throughout the filter.
  roll: number = 0;
  initialized: boolean = false;

  reset(): void {
    this.pitch = 0;
    this.roll = 0;
    this.initialized = false;
  }

  updateAccelerometer(ax: number, ay: number, az: number): boolean {
    if (!Number.isFinite(ax) || !Number.isFinite(ay) || !Number.isFinite(az) ||
      ax * ax + ay * ay + az * az < 0.01) {
      return false;
    }
    const pitchAcc: number = Math.atan2(-ax, Math.sqrt(ay * ay + az * az));
    const rollAcc: number = Math.atan2(ay, az);
    if (!this.initialized) {
      this.pitch = pitchAcc;
      this.roll = rollAcc;
      this.initialized = true;
    } else {
      // Accelerometer callbacks also correct drift when gyro callbacks pause.
      this.pitch = ALPHA * this.pitch + (1 - ALPHA) * pitchAcc;
      this.roll = ALPHA * this.roll + (1 - ALPHA) * rollAcc;
    }
    return true;
  }

  updateGyroscope(pitchRate: number, rollRate: number, dt: number,
    ax: number, ay: number, az: number): boolean {
    if (!this.initialized || !Number.isFinite(dt) || dt <= 0 || dt > MAX_DT_SECONDS ||
      !Number.isFinite(pitchRate) || !Number.isFinite(rollRate)) {
      return false;
    }
    const pitchAcc: number = Math.atan2(-ax, Math.sqrt(ay * ay + az * az));
    const rollAcc: number = Math.atan2(ay, az);
    this.pitch = ALPHA * (this.pitch + pitchRate * dt) + (1 - ALPHA) * pitchAcc;
    this.roll = ALPHA * (this.roll + rollRate * dt) + (1 - ALPHA) * rollAcc;
    return true;
  }
}
