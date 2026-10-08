import { sensor } from '@kit.SensorServiceKit';
import { ComplementaryFilter } from './ComplementaryFilter';
import { InclinometerReading, MeasurementStatus } from '../model/InclinometerReading';

const SENSOR_INTERVAL_NS: number = 20_000_000; // 20 ms, requested 50 Hz.
const UI_INTERVAL_MS: number = 33;
const NS_PER_SECOND: number = 1_000_000_000;
const RAD_TO_DEG: number = 180 / Math.PI;

export class InclinometerController {
  private static visibleController: InclinometerController | undefined;

  static pageVisible(controller: InclinometerController): void {
    InclinometerController.visibleController = controller;
    controller.start();
  }

  static pageHidden(controller: InclinometerController): void {
    if (InclinometerController.visibleController === controller) {
      InclinometerController.visibleController = undefined;
    }
    controller.stop();
  }

  static abilityBackground(): void {
    InclinometerController.visibleController?.stop();
  }

  static abilityForeground(): void {
    InclinometerController.visibleController?.start();
  }

  private filter: ComplementaryFilter = new ComplementaryFilter();
  private active: boolean = false;
  private generation: number = 0;
  private accelSubscribed: boolean = false;
  private gyroSubscribed: boolean = false;
  private hasAcceleration: boolean = false;
  private ax: number = 0;
  private ay: number = 0;
  private az: number = 0;
  private previousGyroTimestamp: number = 0;
  private lastUiTime: number = 0;
  private onReading: (reading: InclinometerReading) => void;

  constructor(onReading: (reading: InclinometerReading) => void) {
    this.onReading = onReading;
  }

  async start(): Promise<void> {
    if (this.active) {
      return;
    }
    this.active = true;
    const session: number = ++this.generation;
    this.filter.reset();
    this.previousGyroTimestamp = 0;
    this.lastUiTime = 0;
    this.hasAcceleration = false;
    try {
      const available: Array<sensor.Sensor> = await sensor.getSensorList();
      if (!this.active || session !== this.generation) {
        return;
      }
      let hasAccel: boolean = false;
      let hasGyro: boolean = false;
      for (const item of available) {
        hasAccel = hasAccel || item.sensorId === sensor.SensorId.ACCELEROMETER;
        hasGyro = hasGyro || item.sensorId === sensor.SensorId.GYROSCOPE;
      }
      if (!hasAccel || !hasGyro) {
        this.fail(MeasurementStatus.SENSOR_UNAVAILABLE);
        return;
      }
      this.accelSubscribed = true;
      sensor.on(sensor.SensorId.ACCELEROMETER, this.accelerometerCallback, { interval: SENSOR_INTERVAL_NS });
      this.gyroSubscribed = true;
      sensor.on(sensor.SensorId.GYROSCOPE, this.gyroscopeCallback, { interval: SENSOR_INTERVAL_NS });
      this.emit(MeasurementStatus.MEASURING);
    } catch (_) {
      if (this.active && session === this.generation) {
        this.fail(MeasurementStatus.ERROR);
      }
    }
  }

  stop(): void {
    ++this.generation;
    this.active = false;
    if (this.gyroSubscribed) {
      this.gyroSubscribed = false;
      try {
        sensor.off(sensor.SensorId.GYROSCOPE, this.gyroscopeCallback);
      } catch (_) {
        // Continue releasing the other sensor if this off call fails.
      }
    }
    if (this.accelSubscribed) {
      this.accelSubscribed = false;
      try {
        sensor.off(sensor.SensorId.ACCELEROMETER, this.accelerometerCallback);
      } catch (_) {
        // The session is inactive; late callbacks are ignored.
      }
    }
    this.hasAcceleration = false;
    this.previousGyroTimestamp = 0;
    this.lastUiTime = 0;
    this.filter.reset();
    this.emit(MeasurementStatus.STOPPED);
  }

  private fail(status: MeasurementStatus): void {
    this.stop();
    this.emit(status);
  }

  private accelerometerCallback = (sample: sensor.AccelerometerResponse): void => {
    if (!this.active) {
      return;
    }
    if (!this.filter.updateAccelerometer(sample.x, sample.y, sample.z)) {
      return;
    }
    this.ax = sample.x;
    this.ay = sample.y;
    this.az = sample.z;
    this.hasAcceleration = true;
    this.publishIfDue();
  };

  private gyroscopeCallback = (sample: sensor.GyroscopeResponse): void => {
    if (!this.active || !this.hasAcceleration || !Number.isFinite(sample.timestamp)) {
      return;
    }
    const previous: number = this.previousGyroTimestamp;
    this.previousGyroTimestamp = sample.timestamp;
    if (previous === 0) {
      return;
    }
    const dt: number = (sample.timestamp - previous) / NS_PER_SECOND;
    if (dt <= 0 || dt > 0.25) {
      // Rebase after a gap; never integrate the whole pause.
      this.filter.reset();
      this.filter.updateAccelerometer(this.ax, this.ay, this.az);
      return;
    }
    // For the chosen screen axes, pitch is rotation about +Y; roll about +X.
    if (this.filter.updateGyroscope(sample.y, sample.x, dt, this.ax, this.ay, this.az)) {
      this.publishIfDue();
    }
  };

  private publishIfDue(): void {
    const now: number = Date.now();
    if (now - this.lastUiTime < UI_INTERVAL_MS) {
      return;
    }
    this.lastUiTime = now;
    this.emit(MeasurementStatus.MEASURING);
  }

  private emit(status: MeasurementStatus): void {
    this.onReading({
      pitch: this.filter.pitch * RAD_TO_DEG,
      roll: this.filter.roll * RAD_TO_DEG,
      status: status
    });
  }
}
