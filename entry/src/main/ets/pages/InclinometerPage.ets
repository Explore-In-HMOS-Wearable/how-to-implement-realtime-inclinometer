import { InclinometerController } from '../sensor/InclinometerController';
import { InclinometerReading, MeasurementStatus } from '../model/InclinometerReading';

@Entry
@Component
struct InclinometerPage {
  @State private pitch: number = 0;
  @State private roll: number = 0;
  @State private status: MeasurementStatus = MeasurementStatus.STOPPED;
  private controller: InclinometerController = new InclinometerController((reading: InclinometerReading) => {
    this.pitch = reading.pitch;
    this.roll = reading.roll;
    this.status = reading.status;
  });

  onPageShow(): void {
    InclinometerController.pageVisible(this.controller);
  }

  onPageHide(): void {
    InclinometerController.pageHidden(this.controller);
  }

  aboutToDisappear(): void {
    InclinometerController.pageHidden(this.controller);
  }

  private clamp(value: number): number {
    return Math.max(-1, Math.min(1, value / 30));
  }

  private statusResource(): Resource {
    switch (this.status) {
      case MeasurementStatus.MEASURING:
        return $r('app.string.status_measuring');
      case MeasurementStatus.SENSOR_UNAVAILABLE:
        return $r('app.string.status_sensor_unavailable');
      case MeasurementStatus.ERROR:
        return $r('app.string.status_error');
      default:
        return $r('app.string.status_stopped');
    }
  }

  build() {
    Column({ space: 5 }) {

      Text($r('app.string.EntryAbility_label'))
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
        .padding(6)

      Stack() {
        Circle().width(112).height(112).fill($r('app.color.level_surface'))
          .stroke($r('app.color.level_border')).strokeWidth(2)
        Rect().width(1).height(98).fill($r('app.color.level_grid'))
        Rect().width(98).height(1).fill($r('app.color.level_grid'))
        Circle().width(8).height(8).fill($r('app.color.level_grid'))
        Circle().width(18).height(18).fill($r('app.color.level_accent'))
          .shadow({ radius: 8, color: $r('app.color.level_accent') })
          // The wearable reports X across the screen and Y along its vertical axis.
          // pitch (-ax) therefore drives the dot horizontally; roll (ay) drives it vertically.
          .translate({ x: this.clamp(this.pitch) * 38, y: this.clamp(this.roll) * 38 })
      }
      .width(118)
      .height(118)

      Text($r('app.string.pitch_value', this.pitch.toFixed(1)))
        .fontSize(18).fontColor($r('app.color.text_primary'))
      Text($r('app.string.roll_value', this.roll.toFixed(1)))
        .fontSize(18).fontColor($r('app.color.text_primary'))
      Text(this.statusResource()).fontSize(12)
        .fontColor(this.status === MeasurementStatus.MEASURING ?
          $r('app.color.level_accent') : $r('app.color.status_warning'))
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor($r('app.color.page_background'))
  }
}
