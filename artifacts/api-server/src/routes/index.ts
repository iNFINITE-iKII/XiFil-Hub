import { Router, type IRouter } from "express";
import healthRouter from "./health.js";
import licenseRouter from "./license.js";

const router: IRouter = Router();

router.use(healthRouter);
router.use("/license", licenseRouter);

export default router;
