package ysyx

import chisel3._
import chisel3.util._

import freechips.rocketchip.amba.apb._
import org.chipsalliance.cde.config.Parameters
import freechips.rocketchip.diplomacy._
import freechips.rocketchip.util._

class CLINTIO extends Bundle {
//   val out = Output(UInt(16.W))
//   val in = Input(UInt(16.W))
//   val seg = Output(Vec(8, UInt(8.W)))
}

class CLINTCtrlIO extends Bundle {
  val clock = Input(Clock())
  val reset = Input(Reset())
  val in = Flipped(new APBBundle(APBBundleParameters(addrBits = 32, dataBits = 32)))
  val clint = new CLINTIO
}

class clint_top_apb extends BlackBox {
  val io = IO(new CLINTCtrlIO)
}

class clintChisel extends Module {
  val io = IO(new CLINTCtrlIO)
}

class APBCLINT(address: Seq[AddressSet])(implicit p: Parameters) extends LazyModule {
  val node = APBSlaveNode(Seq(APBSlavePortParameters(
    Seq(APBSlaveParameters(
      address       = address,
      executable    = true,
      supportsRead  = true,
      supportsWrite = true)),
    beatBytes  = 4)))

  lazy val module = new Impl
  class Impl extends LazyModuleImp(this) {
    val (in, _) = node.in(0)
    val clint_bundle = IO(new CLINTIO)

    val mclint = Module(new clint_top_apb)
    mclint.io.clock := clock
    mclint.io.reset := reset
    mclint.io.in <> in
    clint_bundle <> mclint.io.clint
  }
}
